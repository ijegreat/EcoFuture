;; EcoFuture Lab Smart Contract
;; Description: This contract allows users to create environmental prediction markets,
;; place climate bets, resolve eco outcomes, claim rewards, and handles research expiration.

;; Constants
(define-constant ERROR-INVALID-STUDY-TIME (err u1))
(define-constant ERROR-RESEARCH-INACTIVE (err u2))
(define-constant ERROR-RESEARCH-COMPLETED (err u3))
(define-constant ERROR-INVALID-CONTRIBUTION (err u4))
(define-constant ERROR-RESEARCH-NOT-EXISTS (err u5))
(define-constant ERROR-INSUFFICIENT-GRANTS (err u6))
(define-constant ERROR-RESEARCH-ACTIVE (err u7))
(define-constant ERROR-CONTRIBUTION-NOT-EXISTS (err u8))
(define-constant ERROR-RESEARCH-INCOMPLETE (err u9))
(define-constant ERROR-CONTRIBUTION-INCORRECT (err u10))
(define-constant ERROR-RESEARCH-EXPIRED (err u11))
(define-constant ERROR-RESEARCH-VALID (err u12))
(define-constant ERROR-UNAUTHORIZED (err u13))
(define-constant ERROR-CONTRIBUTION-MIN (err u14))
(define-constant ERROR-CONTRIBUTION-MAX (err u15))
(define-constant ERROR-INVALID-INPUT (err u16))

;; Additional Constants for Validation
(define-constant MAX-BLOCKS-UNTIL-STUDY u52560) ;; Maximum ~1 year worth of blocks
(define-constant MIN-BLOCKS-UNTIL-STUDY u144)   ;; Minimum ~1 day worth of blocks
(define-constant MAX-BLOCKS-UNTIL-COMPLETION u105120) ;; Maximum ~2 years worth of blocks
(define-constant MIN-HYPOTHESIS-LENGTH u10)         ;; Minimum hypothesis description length

;; Data Variables
(define-data-var platform-name (string-ascii 50) "EcoFuture Lab")
(define-data-var next-research-study-id uint u1)
(define-data-var eco-scientist principal tx-sender)

;; Configuration
(define-data-var research-completion-period uint u10000)
(define-data-var minimum-contribution-amount uint u10)
(define-data-var maximum-contribution-amount uint u1000000)

;; Maps
(define-map research-studies
  { study-id: uint }
  {
    hypothesis: (string-ascii 256),
    environmental-result: (optional bool),
    contribution-deadline: uint,
    completion-cutoff: uint,
    lead-researcher: principal
  }
)

(define-map research-contributions
  { study-id: uint, contributor: principal }
  { contribution-amount: uint, outcome-hypothesis: bool }
)

;; Enhanced Private Validation Functions
(define-private (is-valid-study-id (study-id uint))
  (< study-id (var-get next-research-study-id))
)

(define-private (is-valid-hypothesis-length (hypothesis (string-ascii 256)))
  (and 
    (>= (len hypothesis) MIN-HYPOTHESIS-LENGTH)
    (<= (len hypothesis) u256)
  )
)

(define-private (is-valid-study-time (contribution-deadline uint))
  (let 
    (
      (blocks-until-study (- contribution-deadline u0))
    )
    (and
      (>= blocks-until-study MIN-BLOCKS-UNTIL-STUDY)
      (<= blocks-until-study MAX-BLOCKS-UNTIL-STUDY)
    )
  )
)

(define-private (is-valid-completion-time (contribution-deadline uint) (completion-cutoff uint))
  (let
    (
      (blocks-until-completion (- completion-cutoff contribution-deadline))
    )
    (and
      (> completion-cutoff contribution-deadline)
      (<= blocks-until-completion MAX-BLOCKS-UNTIL-COMPLETION)
    )
  )
)

(define-private (is-valid-contribution-amount (amount uint))
  (and
    (>= amount (var-get minimum-contribution-amount))
    (<= amount (var-get maximum-contribution-amount))
  )
)

;; Public Functions

;; Create a new research study with enhanced validation
(define-public (create-research-study (hypothesis (string-ascii 256)) (contribution-deadline uint))
  (let
    (
      (study-id (var-get next-research-study-id))
      (completion-cutoff (+ contribution-deadline (var-get research-completion-period)))
    )
    ;; Enhanced input validation
    (asserts! (is-valid-hypothesis-length hypothesis) ERROR-INVALID-INPUT)
    (asserts! (is-valid-study-time contribution-deadline) ERROR-INVALID-STUDY-TIME)
    (asserts! (is-valid-completion-time contribution-deadline completion-cutoff) ERROR-INVALID-INPUT)
    
    (map-set research-studies
      { study-id: study-id }
      {
        hypothesis: hypothesis,
        environmental-result: none,
        contribution-deadline: contribution-deadline,
        completion-cutoff: completion-cutoff,
        lead-researcher: tx-sender
      }
    )
    (var-set next-research-study-id (+ study-id u1))
    (ok study-id)
  )
)

;; Place a research contribution with enhanced validation
(define-public (place-research-contribution (study-id uint) (outcome-hypothesis bool) (contribution-amount uint))
  (let
    (
      (existing-contribution (default-to { contribution-amount: u0, outcome-hypothesis: false } 
                             (map-get? research-contributions { study-id: study-id, contributor: tx-sender })))
    )
    ;; Enhanced input validation
    (asserts! (is-valid-study-id study-id) ERROR-RESEARCH-NOT-EXISTS)
    (asserts! (is-valid-contribution-amount contribution-amount) ERROR-INVALID-CONTRIBUTION)
    (let
      (
        (research-study (unwrap! (map-get? research-studies { study-id: study-id }) ERROR-RESEARCH-NOT-EXISTS))
        (total-contribution-amount (+ contribution-amount (get contribution-amount existing-contribution)))
      )
      ;; Additional validation for combined contribution amount
      (asserts! (<= total-contribution-amount (var-get maximum-contribution-amount)) ERROR-CONTRIBUTION-MAX)
      (asserts! (is-none (get environmental-result research-study)) ERROR-RESEARCH-COMPLETED)
      (asserts! (>= (stx-get-balance tx-sender) contribution-amount) ERROR-INSUFFICIENT-GRANTS)
      
      (map-set research-contributions
        { study-id: study-id, contributor: tx-sender }
        { contribution-amount: total-contribution-amount, outcome-hypothesis: outcome-hypothesis }
      )
      (stx-transfer? contribution-amount tx-sender (as-contract tx-sender))
    )
  )
)

;; Enhanced setter for research completion period with stricter validation
(define-public (set-research-completion-period (new-period uint))
  (begin
    (asserts! (is-eq tx-sender (var-get eco-scientist)) ERROR-UNAUTHORIZED)
    (asserts! (and 
      (>= new-period u1000)  ;; Minimum ~1 day worth of blocks
      (<= new-period u52560) ;; Maximum ~1 year worth of blocks
    ) ERROR-INVALID-INPUT)
    (ok (var-set research-completion-period new-period))
  )
)

;; Enhanced setter for minimum contribution amount with stricter validation
(define-public (set-minimum-contribution-amount (new-amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get eco-scientist)) ERROR-UNAUTHORIZED)
    (asserts! (and 
      (>= new-amount u1)
      (< new-amount (var-get maximum-contribution-amount))
      (<= new-amount u1000000) ;; Upper limit for minimum contribution
    ) ERROR-INVALID-INPUT)
    (ok (var-set minimum-contribution-amount new-amount))
  )
)

;; Enhanced setter for maximum contribution amount with stricter validation
(define-public (set-maximum-contribution-amount (new-amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get eco-scientist)) ERROR-UNAUTHORIZED)
    (asserts! (and 
      (> new-amount (var-get minimum-contribution-amount))
      (<= new-amount u1000000000000)
      (>= new-amount u1000) ;; Lower limit for maximum contribution
    ) ERROR-INVALID-INPUT)
    (ok (var-set maximum-contribution-amount new-amount))
  )
)

;; Getter for eco scientist
(define-read-only (get-eco-scientist)
  (ok (var-get eco-scientist))
)

;; Function to transfer eco scientist rights
(define-public (transfer-eco-scientist (new-scientist principal))
  (begin
    (asserts! (is-eq tx-sender (var-get eco-scientist)) ERROR-UNAUTHORIZED)
    (asserts! (not (is-eq new-scientist (var-get eco-scientist))) ERROR-INVALID-INPUT)
    (ok (var-set eco-scientist new-scientist))
  )
)