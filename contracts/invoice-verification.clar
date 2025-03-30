;; Invoice Verification Contract
;; This contract validates the legitimacy of submitted invoices

(define-data-var admin principal tx-sender)

;; Invoice structure
(define-map invoices
  { invoice-id: (string-ascii 32) }
  {
    issuer: principal,
    debtor: principal,
    amount: uint,
    due-date: uint,
    verified: bool,
    timestamp: uint
  }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u100)
(define-constant ERR_ALREADY_VERIFIED u101)
(define-constant ERR_INVOICE_NOT_FOUND u102)

;; Submit a new invoice for verification
(define-public (submit-invoice (invoice-id (string-ascii 32)) (debtor principal) (amount uint) (due-date uint))
  (let ((current-time (get-block-info? time (- block-height u1))))
    (if (is-some current-time)
      (begin
        (map-set invoices
          { invoice-id: invoice-id }
          {
            issuer: tx-sender,
            debtor: debtor,
            amount: amount,
            due-date: due-date,
            verified: false,
            timestamp: (unwrap-panic current-time)
          }
        )
        (ok true))
      (err u1))))

;; Verify an invoice (admin only)
(define-public (verify-invoice (invoice-id (string-ascii 32)))
  (let ((invoice (map-get? invoices { invoice-id: invoice-id })))
    (if (is-eq tx-sender (var-get admin))
      (if (is-some invoice)
        (if (get verified (unwrap-panic invoice))
          (err ERR_ALREADY_VERIFIED)
          (begin
            (map-set invoices
              { invoice-id: invoice-id }
              (merge (unwrap-panic invoice) { verified: true })
            )
            (ok true)))
        (err ERR_INVOICE_NOT_FOUND))
      (err ERR_UNAUTHORIZED))))

;; Get invoice details
(define-read-only (get-invoice (invoice-id (string-ascii 32)))
  (map-get? invoices { invoice-id: invoice-id }))

;; Check if invoice is verified
(define-read-only (is-invoice-verified (invoice-id (string-ascii 32)))
  (default-to false (get verified (map-get? invoices { invoice-id: invoice-id }))))

;; Set a new admin
(define-public (set-admin (new-admin principal))
  (if (is-eq tx-sender (var-get admin))
    (begin
      (var-set admin new-admin)
      (ok true))
    (err ERR_UNAUTHORIZED)))
