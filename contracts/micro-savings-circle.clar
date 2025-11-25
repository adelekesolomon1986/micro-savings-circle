;; title: micro-savings-circle
;; version: 1.0.0
;; summary: Rotating Savings and Credit Association (ROSCA) smart contract
;; description: Members contribute fixed amounts weekly, and one member receives the full pot each round

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-member (err u101))
(define-constant err-already-member (err u102))
(define-constant err-circle-full (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-already-contributed (err u105))
(define-constant err-not-all-contributed (err u106))
(define-constant err-already-received (err u107))
(define-constant err-circle-not-started (err u108))
(define-constant err-circle-complete (err u109))

;; data vars
(define-data-var contribution-amount uint u1000000) ;; 1 STX in microSTX
(define-data-var max-members uint u10)
(define-data-var member-count uint u0)
(define-data-var current-round uint u0)
(define-data-var circle-started bool false)
(define-data-var total-rounds uint u0)

;; data maps
(define-map members principal
  {
    member-index: uint,
    has-received: bool,
    joined-round: uint
  }
)

(define-map round-contributions
  { member: principal, round: uint }
  { contributed: bool, amount: uint }
)

(define-map member-by-index uint principal)

;; read only functions
(define-read-only (get-contribution-amount)
  (var-get contribution-amount)
)

(define-read-only (get-max-members)
  (var-get max-members)
)

(define-read-only (get-member-count)
  (var-get member-count)
)

(define-read-only (get-current-round)
  (var-get current-round)
)

(define-read-only (is-circle-started)
  (var-get circle-started)
)

(define-read-only (get-member-info (member principal))
  (map-get? members member)
)

(define-read-only (has-contributed-this-round (member principal))
  (default-to
    false
    (get contributed (map-get? round-contributions { member: member, round: (var-get current-round) }))
  )
)

(define-read-only (get-current-recipient)
  (let
    (
      (round (var-get current-round))
    )
    (if (> round u0)
      (map-get? member-by-index (- round u1))
      none
    )
  )
)

(define-read-only (get-pot-balance)
  (stx-get-balance (as-contract tx-sender))
)

(define-read-only (is-member (user principal))
  (is-some (map-get? members user))
)

;; private functions

;; Helper for fold to check member contribution
(define-private (check-member-contribution (index uint) (all-contributed bool))
  (if (not all-contributed)
    false
    (let
      (
        (member (map-get? member-by-index index))
        (round (var-get current-round))
      )
      (match member
        member-principal
          (default-to false (get contributed (map-get? round-contributions { member: member-principal, round: round })))
        false
      )
    )
  )
)

;; Check if all members have contributed in the current round
(define-private (check-all-contributed)
  (let
    (
      (total-members (var-get member-count))
    )
    (if (is-eq total-members u0)
      false
      (fold check-member-contribution (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9) true)
    )
  )
)

;; public functions

;; Join the savings circle
(define-public (join-circle)
  (let
    (
      (current-members (var-get member-count))
      (max (var-get max-members))
    )
    (asserts! (not (var-get circle-started)) err-circle-not-started)
    (asserts! (is-none (map-get? members tx-sender)) err-already-member)
    (asserts! (< current-members max) err-circle-full)

    (map-set members tx-sender {
      member-index: current-members,
      has-received: false,
      joined-round: u0
    })

    (map-set member-by-index current-members tx-sender)
    (var-set member-count (+ current-members u1))

    (ok true)
  )
)

;; Start the circle (only owner)
(define-public (start-circle)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (var-get circle-started)) err-circle-not-started)
    (asserts! (> (var-get member-count) u0) err-not-member)

    (var-set circle-started true)
    (var-set current-round u1)
    (var-set total-rounds (var-get member-count))

    (ok true)
  )
)

;; Contribute to the current round
(define-public (contribute)
  (let
    (
      (amount (var-get contribution-amount))
      (round (var-get current-round))
      (member-data (unwrap! (map-get? members tx-sender) err-not-member))
    )
    (asserts! (var-get circle-started) err-circle-not-started)
    (asserts! (<= round (var-get total-rounds)) err-circle-complete)
    (asserts! (not (has-contributed-this-round tx-sender)) err-already-contributed)

    ;; Transfer STX to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

    ;; Record contribution
    (map-set round-contributions
      { member: tx-sender, round: round }
      { contributed: true, amount: amount }
    )

    (ok true)
  )
)

;; Distribute the pot to the current round's recipient
(define-public (distribute-pot)
  (let
    (
      (round (var-get current-round))
      (recipient (unwrap! (get-current-recipient) err-not-member))
      (recipient-data (unwrap! (map-get? members recipient) err-not-member))
      (pot (get-pot-balance))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (var-get circle-started) err-circle-not-started)
    (asserts! (<= round (var-get total-rounds)) err-circle-complete)
    (asserts! (not (get has-received recipient-data)) err-already-received)
    (asserts! (check-all-contributed) err-not-all-contributed)

    ;; Update recipient status
    (map-set members recipient
      (merge recipient-data { has-received: true })
    )

    ;; Transfer pot to recipient
    (try! (as-contract (stx-transfer? pot tx-sender recipient)))

    ;; Move to next round
    (var-set current-round (+ round u1))

    (ok true)
  )
)
