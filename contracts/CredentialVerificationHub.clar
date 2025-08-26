;; CredentialVerification Hub Smart Contract
;; Academic and professional credential verification without revealing personal information
;; Uses zero-knowledge proof concepts with cryptographic hashes

;; Define the contract owner
(define-constant contract-owner tx-sender)

;; Error constants
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-credential-exists (err u102))
(define-constant err-credential-not-found (err u103))
(define-constant err-invalid-hash (err u104))
(define-constant err-invalid-institution (err u105))

;; Data variables
(define-data-var total-credentials uint u0)
(define-data-var total-verifications uint u0)

;; Maps to store credential data
;; credential-hash -> {institution-id, credential-type, issue-date, is-active}
(define-map credentials 
  (buff 32)  ;; credential hash (32 bytes)
  {
    institution-id: (string-ascii 50),
    credential-type: (string-ascii 20),  ;; "academic" or "professional"
    issue-date: uint,
    is-active: bool
  }
)

;; Map to store authorized institutions
;; institution-id -> {name, is-verified}
(define-map authorized-institutions
  (string-ascii 50)
  {
    name: (string-ascii 100),
    is-verified: bool,
    authorized-by: principal
  }
)

;; Map to track verification attempts
;; verifier-principal -> verification-count
(define-map verification-logs principal uint)

;; Function 1: Issue Credential
;; Only authorized institutions can issue credentials
(define-public (issue-credential 
  (credential-hash (buff 32))
  (institution-id (string-ascii 50))
  (credential-type (string-ascii 20)))
  (let (
    (institution-data (map-get? authorized-institutions institution-id))
    (existing-credential (map-get? credentials credential-hash))
  )
  (begin
    ;; Check if institution is authorized
    (asserts! (is-some institution-data) err-invalid-institution)
    (asserts! (get is-verified (unwrap! institution-data err-invalid-institution)) err-not-authorized)
    
    ;; Check if credential already exists
    (asserts! (is-none existing-credential) err-credential-exists)
    
    ;; Validate credential type
    (asserts! (or (is-eq credential-type "academic") 
                  (is-eq credential-type "professional")) err-invalid-hash)
    
    ;; Store the credential
    (map-set credentials credential-hash
      {
        institution-id: institution-id,
        credential-type: credential-type,
        issue-date: stacks-block-height,
        is-active: true
      }
    )
    
    ;; Increment total credentials count
    (var-set total-credentials (+ (var-get total-credentials) u1))
    
    ;; Print event for indexing
    (print {
      event: "credential-issued",
      credential-hash: credential-hash,
      institution-id: institution-id,
      credential-type: credential-type,
      issue-date: stacks-block-height
    })
    
    (ok true)
  )))
