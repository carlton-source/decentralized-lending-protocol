;; DeFi Lending Engine: Secure, Transparent, and Efficient
;; A next-generation decentralized lending protocol enabling collateralized loans with risk-managed positions,
;; automated interest rate accrual, and community-driven liquidation mechanisms.

;; Protocol Overview:
;; - Users deposit STX as collateral to borrow against their assets
;; - Dynamic interest rates with protocol-managed fee distribution
;; - Real-time collateral ratio monitoring and liquidations
;; - Fully transparent on-chain accounting with real-time yield tracking
;; - Robust safety mechanisms including circuit breakers and overflow protection

;; Key Features:
;; 1. Collateral Management: Deposit/withdraw assets with enforced collateral ratios
;; 2. Debt Positions: Create and manage leveraged positions with interest accrual per block
;; 3. Risk Management: Automated liquidations below maintenance threshold
;; 4. Protocol Economics: Fee capture mechanism for sustainable operations
;; 5. Real-time Analytics: On-chain tracking of loan health and market statistics

;; Technical Highlights:
;; - Overflow-protected arithmetic operations
;; - stacks-block-height-based interest calculation
;; - Loan state machine with active/repaid/liquidated states
;; - Gas-efficient position management
;; - Administrative safeguards with emergency pause functionality

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-INSUFFICIENT-BALANCE (err u402))
(define-constant ERR-INVALID-AMOUNT (err u403))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u404))
(define-constant ERR-LOAN-NOT-FOUND (err u405))
(define-constant ERR-LOAN-ALREADY-EXISTS (err u406))
(define-constant ERR-MATH-OVERFLOW (err u407))
(define-constant ERR-LOAN-NOT-LIQUIDATABLE (err u408))
(define-constant ERR-LOAN-NOT-REPAYABLE (err u409))
(define-constant ERR-INVALID-LOAN-ID (err u410))

;; Configuration constants
(define-constant COLLATERAL-RATIO u150) ;; 150% minimum collateral ratio
(define-constant LIQUIDATION-THRESHOLD u130) ;; 130% liquidation threshold
(define-constant INTEREST-RATE-YEARLY u50) ;; 5.0% annual interest (scaled by 10)
(define-constant BLOCKS-PER-YEAR u52560) ;; ~10 minute blocks, 365 days
(define-constant INTEREST-RATE-PER-BLOCK (/ (* INTEREST-RATE-YEARLY u100000) (* BLOCKS-PER-YEAR u1000)))
(define-constant PROTOCOL-FEE-PERCENT u10) ;; 1.0% protocol fee from interest (scaled by 10)

;; Data structures
(define-map user-deposits principal uint)
(define-map total-deposits uint uint) ;; [height, amount]
(define-map protocol-fees uint uint) ;; [height, amount] - Fixed: Added value type

;; Loan tracking
(define-map loans 
  { loan-id: uint }
  {
    borrower: principal,
    collateral-amount: uint,
    loan-amount: uint,
    interest-accumulated: uint,
    creation-height: uint,
    last-interest-height: uint,
    status: (string-ascii 20)
  }
)

(define-map user-loans 
  principal 
  (list 20 uint)
) ;; Maps user to list of their loan IDs

(define-data-var loan-nonce uint u0)
(define-data-var total-collateral uint u0)
(define-data-var total-borrowed uint u0)
(define-data-var paused bool false)

;; Administrative functions
(define-public (set-paused (paused-state bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set paused paused-state)
    (ok paused-state)
  )
)

;; Helper functions
(define-read-only (get-current-stacks-block-height)
  stacks-block-height
)

(define-read-only (get-user-deposit (user principal))
  (default-to u0 (map-get? user-deposits user))
)

(define-read-only (get-loan-details (loan-id uint))
  (map-get? loans { loan-id: loan-id })
)

(define-read-only (get-user-loans (user principal))
  (default-to (list) (map-get? user-loans user))
)