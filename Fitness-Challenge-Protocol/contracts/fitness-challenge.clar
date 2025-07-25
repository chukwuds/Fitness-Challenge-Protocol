;; Fitness Challenge Protocol - Gamified health goals with proof-of-exercise verification
;; This contract enables users to create fitness challenges, submit proof of exercise,
;; and earn rewards for completing fitness goals

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-challenge-ended (err u104))
(define-constant err-challenge-not-ended (err u105))
(define-constant err-already-joined (err u106))
(define-constant err-not-participant (err u107))
(define-constant err-insufficient-proof (err u108))
(define-constant err-already-verified (err u109))

;; Data Variables
(define-data-var challenge-counter uint u0)
(define-data-var total-rewards-distributed uint u0)

;; Data Maps
(define-map challenges
  { challenge-id: uint }
  {
    creator: principal,
    title: (string-utf8 100),
    description: (string-utf8 500),
    goal-type: (string-ascii 50),
    target-value: uint,
    duration-blocks: uint,
    start-block: uint,
    end-block: uint,
    entry-fee: uint,
    reward-pool: uint,
    max-participants: uint,
    current-participants: uint,
    is-active: bool,
    verification-required: bool
  }
)

(define-map participants
  { challenge-id: uint, participant: principal }
  {
    joined-block: uint,
    progress: uint,
    proof-submissions: uint,
    completed: bool,
    verified: bool,
    reward-claimed: bool
  }
)

(define-map exercise-proofs
  { challenge-id: uint, participant: principal, proof-id: uint }
  {
    exercise-type: (string-ascii 50),
    value: uint,
    proof-hash: (buff 32),
    timestamp: uint,
    verified: bool,
    verifier: (optional principal)
  }
)

(define-map participant-rewards
  { participant: principal }
  {
    total-earned: uint,
    challenges-completed: uint,
    current-streak: uint,
    best-streak: uint
  }
)

;; Read-only functions
(define-read-only (get-challenge (challenge-id uint))
  (map-get? challenges { challenge-id: challenge-id })
)

(define-read-only (get-participant-info (challenge-id uint) (participant principal))
  (map-get? participants { challenge-id: challenge-id, participant: participant })
)

(define-read-only (get-exercise-proof (challenge-id uint) (participant principal) (proof-id uint))
  (map-get? exercise-proofs { challenge-id: challenge-id, participant: participant, proof-id: proof-id })
)

(define-read-only (get-participant-rewards (participant principal))
  (default-to 
    { total-earned: u0, challenges-completed: u0, current-streak: u0, best-streak: u0 }
    (map-get? participant-rewards { participant: participant })
  )
)

(define-read-only (get-challenge-counter)
  (var-get challenge-counter)
)

(define-read-only (get-total-rewards-distributed)
  (var-get total-rewards-distributed)
)

(define-read-only (is-challenge-active (challenge-id uint))
  (match (get-challenge challenge-id)
    challenge-data 
      (and 
        (get is-active challenge-data)
        (>= block-height (get start-block challenge-data))
        (<= block-height (get end-block challenge-data))
      )
    false
  )
)

(define-read-only (calculate-reward-share (challenge-id uint) (participant principal))
  (match (get-challenge challenge-id)
    challenge-data
      (match (get-participant-info challenge-id participant)
        participant-data
          (if (and (get completed participant-data) (get verified participant-data))
            (/ (get reward-pool challenge-data) (get current-participants challenge-data))
            u0
          )
        u0
      )
    u0
  )
)

;; Public functions
(define-public (create-challenge 
  (title (string-utf8 100))
  (description (string-utf8 500))
  (goal-type (string-ascii 50))
  (target-value uint)
  (duration-blocks uint)
  (entry-fee uint)
  (max-participants uint)
  (verification-required bool)
)
  (let 
    (
      (challenge-id (+ (var-get challenge-counter) u1))
      (start-block (+ block-height u10))
      (end-block (+ start-block duration-blocks))
    )
    (try! (stx-transfer? entry-fee tx-sender (as-contract tx-sender)))
    (map-set challenges
      { challenge-id: challenge-id }
      {
        creator: tx-sender,
        title: title,
        description: description,
        goal-type: goal-type,
        target-value: target-value,
        duration-blocks: duration-blocks,
        start-block: start-block,
        end-block: end-block,
        entry-fee: entry-fee,
        reward-pool: entry-fee,
        max-participants: max-participants,
        current-participants: u0,
        is-active: true,
        verification-required: verification-required
      }
    )
    (var-set challenge-counter challenge-id)
    (ok challenge-id)
  )
)

(define-public (join-challenge (challenge-id uint))
  (let 
    (
      (challenge-data (unwrap! (get-challenge challenge-id) err-not-found))
      (participant-exists (is-some (get-participant-info challenge-id tx-sender)))
    )
    (asserts! (not participant-exists) err-already-joined)
    (asserts! (is-challenge-active challenge-id) err-challenge-ended)
    (asserts! (< (get current-participants challenge-data) (get max-participants challenge-data)) err-unauthorized)
    
    (try! (stx-transfer? (get entry-fee challenge-data) tx-sender (as-contract tx-sender)))
    
    (map-set participants
      { challenge-id: challenge-id, participant: tx-sender }
      {
        joined-block: block-height,
        progress: u0,
        proof-submissions: u0,
        completed: false,
        verified: false,
        reward-claimed: false
      }
    )
    
    (map-set challenges
      { challenge-id: challenge-id }
      (merge challenge-data {
        current-participants: (+ (get current-participants challenge-data) u1),
        reward-pool: (+ (get reward-pool challenge-data) (get entry-fee challenge-data))
      })
    )
    (ok true)
  )
)

(define-public (submit-exercise-proof 
  (challenge-id uint)
  (exercise-type (string-ascii 50))
  (value uint)
  (proof-hash (buff 32))
)
  (let 
    (
      (challenge-data (unwrap! (get-challenge challenge-id) err-not-found))
      (participant-data (unwrap! (get-participant-info challenge-id tx-sender) err-not-participant))
      (proof-id (+ (get proof-submissions participant-data) u1))
    )
    (asserts! (is-challenge-active challenge-id) err-challenge-ended)
    (asserts! (> value u0) err-invalid-amount)
    
    (map-set exercise-proofs
      { challenge-id: challenge-id, participant: tx-sender, proof-id: proof-id }
      {
        exercise-type: exercise-type,
        value: value,
        proof-hash: proof-hash,
        timestamp: block-height,
        verified: (not (get verification-required challenge-data)),
        verifier: none
      }
    )
    
    (let ((new-progress (+ (get progress participant-data) value)))
      (map-set participants
        { challenge-id: challenge-id, participant: tx-sender }
        (merge participant-data {
          progress: new-progress,
          proof-submissions: proof-id,
          completed: (>= new-progress (get target-value challenge-data)),
          verified: (if (get verification-required challenge-data) false true)
        })
      )
    )
    (ok proof-id)
  )
)

(define-public (verify-exercise-proof 
  (challenge-id uint)
  (participant principal)
  (proof-id uint)
  (approved bool)
)
  (let 
    (
      (challenge-data (unwrap! (get-challenge challenge-id) err-not-found))
      (proof-data (unwrap! (get-exercise-proof challenge-id participant proof-id) err-not-found))
      (participant-data (unwrap! (get-participant-info challenge-id participant) err-not-participant))
    )
    (asserts! (or (is-eq tx-sender (get creator challenge-data)) (is-eq tx-sender contract-owner)) err-unauthorized)
    (asserts! (get verification-required challenge-data) err-unauthorized)
    (asserts! (not (get verified proof-data)) err-already-verified)
    
    (map-set exercise-proofs
      { challenge-id: challenge-id, participant: participant, proof-id: proof-id }
      (merge proof-data {
        verified: approved,
        verifier: (some tx-sender)
      })
    )
    
    (if approved
      (map-set participants
        { challenge-id: challenge-id, participant: participant }
        (merge participant-data { verified: (>= (get progress participant-data) (get target-value challenge-data)) })
      )
      true
    )
    (ok approved)
  )
)

(define-public (claim-reward (challenge-id uint))
  (let 
    (
      (challenge-data (unwrap! (get-challenge challenge-id) err-not-found))
      (participant-data (unwrap! (get-participant-info challenge-id tx-sender) err-not-participant))
      (current-rewards (get-participant-rewards tx-sender))
    )
    (asserts! (> block-height (get end-block challenge-data)) err-challenge-not-ended)
    (asserts! (get completed participant-data) err-insufficient-proof)
    (asserts! (get verified participant-data) err-unauthorized)
    (asserts! (not (get reward-claimed participant-data)) err-unauthorized)
    
    (let ((reward-amount (calculate-reward-share challenge-id tx-sender)))
      (asserts! (> reward-amount u0) err-invalid-amount)
      
      (try! (as-contract (stx-transfer? reward-amount tx-sender tx-sender)))
      
      (map-set participants
        { challenge-id: challenge-id, participant: tx-sender }
        (merge participant-data { reward-claimed: true })
      )
      
      (map-set participant-rewards
        { participant: tx-sender }
        {
          total-earned: (+ (get total-earned current-rewards) reward-amount),
          challenges-completed: (+ (get challenges-completed current-rewards) u1),
          current-streak: (+ (get current-streak current-rewards) u1),
          best-streak: (max (+ (get current-streak current-rewards) u1) (get best-streak current-rewards))
        }
      )
      
      (var-set total-rewards-distributed (+ (var-get total-rewards-distributed) reward-amount))
      (ok reward-amount)
    )
  )
)

(define-public (end-challenge (challenge-id uint))
  (let ((challenge-data (unwrap! (get-challenge challenge-id) err-not-found)))
    (asserts! (is-eq tx-sender (get creator challenge-data)) err-unauthorized)
    (asserts! (get is-active challenge-data) err-not-found)
    
    (map-set challenges
      { challenge-id: challenge-id }
      (merge challenge-data { is-active: false })
    )
    (ok true)
  )
)

;; Emergency functions (owner only)
(define-public (emergency-withdraw (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (as-contract (stx-transfer? amount tx-sender contract-owner))
  )
)

(define-public (update-challenge-status (challenge-id uint) (active bool))
  (let ((challenge-data (unwrap! (get-challenge challenge-id) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set challenges
      { challenge-id: challenge-id }
      (merge challenge-data { is-active: active })
    )
    (ok true)
  )
)