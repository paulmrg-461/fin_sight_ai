# Spec: OCR receipt scanning

## Objective

Scan a receipt image, extract merchant, date, total, currency, and line items, let the user correct them, persist the receipt, and automatically create an expense transaction.

## Entity

`ReceiptEntity extends Entity`

| Field | Type | Rules |
| --- | --- | --- |
| `id` | `String` | UUID v4 |
| `imagePath` | `String` | Trimmed, non-empty |
| `merchantName` | `String` | Trimmed, non-empty |
| `date` | `DateTime` | Parsed or `now` fallback |
| `totalAmount` | `double` | Finite, `> 0`, 2 decimals |
| `items` | `List<ReceiptItem>` | Name non-empty, quantity `> 0`, price `>= 0` |
| `currency` | `String` | 3-letter ISO code, uppercase |

`ReceiptItem`: `name`, `quantity`, `price`, derived `lineTotal`.

## Repository

```dart
ResultFuture<ReceiptEntity> scanReceipt(String imagePath);
ResultFuture<ReceiptEntity> saveReceipt(ReceiptEntity receipt);
ResultFuture<List<ReceiptEntity>> getReceipts();
```

## Use cases

- `ScanReceiptUseCase` — rejects a blank image path.
- `SaveReceiptUseCase` — validates/normalizes merchant, currency, totals, items, and id.
- `GetReceiptsUseCase` — returns saved receipts, newest first.

## Data

- `OcrDataSource` contract; `MlKitOcrDataSource` uses Google ML Kit (Android/iOS).
- `ReceiptParser` extracts merchant (first text line), dates (ISO and dd/MM/yyyy with mm/dd fallback when unambiguous), totals (TOTAL line, else largest amount), currency codes/symbols, and line items (`name qty x price` or `name price`).
- `ReceiptModel` JSON round-trip with nested items.
- `HiveReceiptLocalDataSource` stores JSON maps in the `receipts` box.
- `ReceiptRepositoryImpl` maps `OcrException` to `ServerFailure` and `CacheException` to `CacheFailure`; empty OCR text becomes `ValidationFailure` (`ocr_empty_text`).

## Presentation

`OcrBloc` events: `ScanReceipt`, `SaveReceipt`, `LoadReceipts`.

States: initial, loading, receipts loaded, empty, scanning, scan success, saving, saved, failure.

- `OcrScreen` — camera/gallery actions through `ReceiptImagePicker`, saved receipts list, retry/empty/loading states.
- `ReceiptPreviewScreen` — editable merchant, total, currency, date, and items; saving a newly scanned receipt also creates an expense transaction (`category: Receipts`, transaction id = receipt id) so retries stay idempotent.

## Verification

```bash
flutter analyze
flutter test --coverage
```
