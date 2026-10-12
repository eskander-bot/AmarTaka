# Amar Taka 0.4 — offline finance modules

The uploaded reference archive was used to identify capabilities. Its README says MIT but does not include a license/copyright file. No reference implementation, logo, icon asset, APK, or generated database code is included in this project. New modules use Amar Taka's existing SQLite and integer-paisa foundation.

| Reference capability | Amar Taka entry point / behavior |
| --- | --- |
| Cash wallets and bank balances | Home → সম্পদ ও দায়; multiple accounts, opening balance, deposits, withdrawals, transfers, history |
| DPS | সম্পদ ও দায় → DPS; monthly installment, manually confirmed paid count, maturity estimate, active/closed state |
| FDR | সম্পদ ও দায় → FDR; principal, own annual rate, dates, capped accrued and maturity estimates |
| Savings certificates | সম্পদ ও দায় → সঞ্চয়পত্র; scheme name, own rate, principal, dates, estimate |
| Investments | সম্পদ ও দায় → বিনিয়োগ; type, cost, current value, P&L and ROI |
| Lend/borrow | সম্পদ ও দায়; people, partial repayment, outstanding and settled status |
| Net worth | Assets minus outstanding borrowing; account holdings and savings principal, investment current values, outstanding lending |
| Category budgets | পরিকল্পনা → ক্যাটাগরি অনুযায়ী বাজেট; real expense totals, remaining/over-budget state |
| Reports | রিপোর্ট; six-month comparative bars, category donut, savings rate and disclosed app score |
| Income/expense and date grouping | Existing লেনদেন tab, source/category and text filters, daily headings |
| Biometrics | আরও; requires existing PIN fallback, authenticate to enable, fingerprint/face device prompt |
| Profile and reset | আরও → name; explicit DELETE confirmation and PIN verification for reset |
| Themes | Existing light/dark/AMOLED/system selection |

All modules are local and require no account or bank connection. Account movements are a separate balance register: they do not create income/expense entries. Transfers preserve total assets. Do not add the ledger's cumulative income-minus-expense balance to net worth a second time. Closing a savings record excludes it; enter any released money into its destination account yourself.

Savings figures are estimates, not product quotations: user supplies the rate; no old Bangladesh scheme rate is hard-coded. FDR and certificate estimates use simple interest on actual calendar days/365 capped at maturity. DPS estimates assume beginning-of-month deposits and monthly compounding, but net worth counts only installments the user recorded. Estimates exclude taxes/fees/early withdrawal rules.

Database schema 3 adds holdings, account movements and category budgets without changing earlier records. JSON schema 3 contains all financial records; schema 2 imports remain supported and initialize new modules empty. Restoring replaces the financial snapshot after validation and confirmation. Theme, name, PIN and biometric settings are device preferences and are not exported. CSV remains the daily income/expense ledger export.

The score is a transparent app heuristic, not a credit rating: savings fraction 40%, cash buffer versus six months' expenses 35%, assets less debt ratio 25%. Missing inputs earn no points.

Android biometric behavior and installation/update must also be checked on a physical enrolled phone. Preview APKs are testing builds; production signing and Play Store preparation remain separate.
