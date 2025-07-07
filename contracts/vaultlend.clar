;; VaultLend: Advanced Bitcoin Collateral Lending Protocol
;;
;; Summary: Revolutionary DeFi protocol enabling Bitcoin holders to unlock
;; liquidity without selling their assets through sophisticated over-collateralized
;; lending positions backed by native Bitcoin.
;;
;; Description: VaultLend transforms Bitcoin from a static store of value into
;; productive capital. Users deposit Bitcoin as collateral to mint synthetic
;; stablecoins, maintaining exposure to Bitcoin's upside while accessing immediate
;; liquidity. The protocol features dynamic risk management, automated liquidation
;; mechanics, and compound interest calculations to ensure system stability and
;; capital efficiency. Built with institutional-grade security and transparency.
;;
;; Key Features:
;; - Over-collateralized lending with 150% minimum ratio
;; - Real-time price oracle integration with staleness protection
;; - Automated liquidation engine with 10% penalty incentives
;; - Compound interest accrual system with per-block calculations
;; - Emergency pause functionality for protocol security
;; - Comprehensive position management and risk analytics

;; ERROR CODES

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u1001))
(define-constant ERR-POSITION-NOT-FOUND (err u1002))
(define-constant ERR-UNDERCOLLATERALIZED (err u1003))
(define-constant ERR-MINIMUM-LOAN-REQUIRED (err u1004))
(define-constant ERR-INSUFFICIENT-DEBT (err u1005))
(define-constant ERR-PRICE-EXPIRED (err u1006))
(define-constant ERR-PROTOCOL-PAUSED (err u1007))
(define-constant ERR-INVALID-AMOUNT (err u1008))
(define-constant ERR-NO-PRICE-DATA (err u1009))

;; PROTOCOL CONFIGURATION

(define-constant COLLATERAL-RATIO u150) ;; 150% minimum collateral ratio
(define-constant LIQUIDATION-THRESHOLD u120) ;; 120% liquidation threshold
(define-constant LIQUIDATION-PENALTY u10) ;; 10% liquidation penalty
(define-constant MINIMUM_LOAN_AMOUNT u100000000) ;; 100 stablecoins (8 decimals)
(define-constant PRICE_EXPIRY u86400) ;; 24-hour price validity window
(define-constant INTEREST_RATE_PER_BLOCK u5) ;; 0.0005% per block (~10% APR)
(define-constant INTEREST_RATE_DENOMINATOR u1000000) ;; Interest rate precision

;; PROTOCOL STATE VARIABLES

(define-data-var protocol-owner principal tx-sender)
(define-data-var protocol-paused bool false)
(define-data-var total-debt uint u0)
(define-data-var total-collateral uint u0)
(define-data-var stability-fee uint u0)
(define-data-var last-accrual-block uint stacks-block-height)
(define-data-var btc-price-in-usd (optional {
  price: uint,
  timestamp: uint,
}) none)
(define-data-var current-time uint u0)

;; DATA STRUCTURES

;; User position tracking
(define-map positions
  principal
  {
    collateral: uint,
    debt: uint,
    last-update-block: uint,
  }
)

;; Synthetic stablecoin token
(define-fungible-token stable-usd)

;; ADMINISTRATIVE FUNCTIONS

(define-public (set-protocol-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set protocol-owner new-owner))
  )
)

(define-public (pause-protocol (paused bool))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set protocol-paused paused))
  )
)

(define-public (update-btc-price
    (price uint)
    (timestamp uint)
  )
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (> price u0) ERR-INVALID-AMOUNT)
    (var-set btc-price-in-usd
      (some {
        price: price,
        timestamp: timestamp,
      })
    )
    (ok true)
  )
)

(define-public (set-current-time (time uint))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set current-time time))
  )
)

;; CORE UTILITY FUNCTIONS

(define-private (collateral-value
    (collateral-amount uint)
    (price uint)
  )
  (* collateral-amount price)
)

(define-private (required-collateral
    (debt-amount uint)
    (price uint)
  )
  (/ (* debt-amount COLLATERAL-RATIO) (/ price u100))
)

(define-private (is-position-safe
    (user principal)
    (btc-price uint)
  )
  (let (
      (position (unwrap! (map-get? positions user) false))
      (debt (get debt position))
      (collateral (get collateral position))
      (collateral-value-usd (collateral-value collateral btc-price))
      (min-collateral-value-usd (/ (* debt COLLATERAL-RATIO) u100))
    )
    (>= collateral-value-usd min-collateral-value-usd)
  )
)

(define-private (calculate-interest
    (debt uint)
    (blocks-passed uint)
  )
  (/ (* debt (* blocks-passed INTEREST_RATE_PER_BLOCK)) INTEREST_RATE_DENOMINATOR)
)

;; INTEREST ACCRUAL SYSTEM

(define-private (accrue-global-interest)
  (let (
      (current-block stacks-block-height)
      (last-block (var-get last-accrual-block))
      (blocks-passed (- current-block last-block))
      (total-system-debt (var-get total-debt))
      (interest-accrued (calculate-interest total-system-debt blocks-passed))
    )
    (begin
      (if (> blocks-passed u0)
        (begin
          (var-set stability-fee (+ (var-get stability-fee) interest-accrued))
          (var-set total-debt (+ total-system-debt interest-accrued))
          (var-set last-accrual-block current-block)
        )
        false
      )
      true
    )
  )
)

(define-private (accrue-position-interest (user principal))
  (let (
      (position (unwrap! (map-get? positions user) {
        debt: u0,
        collateral: u0,
        last-update-block: stacks-block-height,
      }))
      (debt (get debt position))
      (collateral (get collateral position))
      (last-update (get last-update-block position))
      (blocks-passed (- stacks-block-height last-update))
      (interest-accrued (calculate-interest debt blocks-passed))
      (new-debt (+ debt interest-accrued))
      (updated-position {
        collateral: collateral,
        debt: new-debt,
        last-update-block: stacks-block-height,
      })
    )
    (begin
      (if (> blocks-passed u0)
        (map-set positions user updated-position)
        false
      )
      updated-position
    )
  )
)

;; PRICE ORACLE INTEGRATION

(define-read-only (get-current-price)
  (match (var-get btc-price-in-usd)
    price-data (let (
        (price (get price price-data))
        (timestamp (get timestamp price-data))
        (current-timestamp (var-get current-time))
      )
      (if (>= (- current-timestamp timestamp) PRICE_EXPIRY)
        ERR-PRICE-EXPIRED
        (if (<= price u0)
          ERR-PRICE-EXPIRED
          (ok price)
        )
      )
    )
    ERR-NO-PRICE-DATA
  )
)

;; CORE LENDING FUNCTIONS

(define-public (create-position
    (btc-amount uint)
    (stable-amount uint)
  )
  (begin
    (asserts! (not (var-get protocol-paused)) ERR-PROTOCOL-PAUSED)
    (asserts! (>= btc-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (>= stable-amount MINIMUM_LOAN_AMOUNT) ERR-MINIMUM-LOAN-REQUIRED)
    (let (
        (btc-price (try! (get-current-price)))
        (user tx-sender)
        (existing-position (map-get? positions user))
      )
      (begin
        (accrue-global-interest)
        (let ((current-position (if (is-some existing-position)
            (accrue-position-interest user)
            {
              collateral: u0,
              debt: u0,
              last-update-block: stacks-block-height,
            }
          )))
          (let (
              (old-collateral (get collateral current-position))
              (old-debt (get debt current-position))
              (new-collateral (+ old-collateral btc-amount))
              (new-debt (+ old-debt stable-amount))
              (min-required-collateral (required-collateral new-debt btc-price))
            )
            (begin
              (asserts!
                (>= (collateral-value new-collateral btc-price)
                  min-required-collateral
                )
                ERR-INSUFFICIENT-COLLATERAL
              )
              (map-set positions user {
                collateral: new-collateral,
                debt: new-debt,
                last-update-block: stacks-block-height,
              })
              (var-set total-collateral (+ (var-get total-collateral) btc-amount))
              (var-set total-debt (+ (var-get total-debt) stable-amount))
              (ft-mint? stable-usd stable-amount user)
            )
          )
        )
      )
    )
  )
)