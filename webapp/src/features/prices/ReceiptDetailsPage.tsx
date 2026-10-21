// One saved receipt (receipt_details_page.dart): its header, every price read
// from it (a tap records a corrected price), renaming the store on the receipt
// and its prices, and deleting it with or without its prices.
import { useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { useAuth } from "../../lib/auth";
import { useI18n } from "../../lib/i18n";
import { Icon } from "../../components/icons";
import { Notice } from "../../components/ui";
import { printedNameOf, type PriceRecord } from "../../models/priceRecord";
import { receiptHasImages } from "../../models/receipt";
import { EmptyState, IconButton, Loading, formatAmount, priceLabel, usePrompt, useStatus } from "../groceries/kit";
import { ReceiptGoneError, deleteReceipt, renameReceiptStore, usePriceBook } from "./priceBook";
import { AddPriceDialog, useDeleteReceiptChoice, usePriceUnitLabel, useShortDate } from "./dialogs";
import { useIsPhone } from "../../components/useIsPhone";
import { PhoneBar } from "../../components/PhoneBar";
import { ClayCard, ClayIconButton, EmptyState as ClayEmptyState, LoadingSpinner, PageHeader } from "../../components/clay";

export function ReceiptDetailsPage() {
  const { id = "" } = useParams();
  const { t } = useI18n();
  const { user } = useAuth();
  const navigate = useNavigate();
  const book = usePriceBook(user?.uid);
  const date = useShortDate();
  const unitLabel = usePriceUnitLabel();
  const status = useStatus();
  const prompt = usePrompt();
  const choice = useDeleteReceiptChoice();
  const [busy, setBusy] = useState(false);
  const [editing, setEditing] = useState<PriceRecord | null>(null);

  const phone = useIsPhone();
  const receipt = book.receipts?.find((r) => r.id === id) ?? null;
  const lines = useMemo(() => (book.records ?? []).filter((r) => r.receiptId === id), [book.records, id]);

  const back = (
    <Link to="/prices" className="mb-4 inline-flex items-center gap-1 text-label-md text-primary">
      <span className="rtl:rotate-180" aria-hidden="true">
        <Icon name="back" size={18} />
      </span>
      {t("prices.backToPrices")}
    </Link>
  );

  if (phone && (book.receipts === null || book.records === null || !receipt)) {
    return (
      <>
        <PhoneBar title={t("prices.receipts")} back="/prices" />
        {book.receipts === null || book.records === null ? (
          book.error ? <Notice kind="error">{t("groceries.common.loadFailed")}</Notice> : <LoadingSpinner label={t("common.loading")} />
        ) : (
          <ClayEmptyState icon="receipt_long" message={t("prices.receiptNotFound")} />
        )}
      </>
    );
  }
  if (book.receipts === null || book.records === null)
    return book.error ? (
      <>
        {back}
        <Notice kind="error">{t("groceries.common.loadFailed")}</Notice>
      </>
    ) : (
      <Loading />
    );
  if (!receipt)
    return (
      <>
        {back}
        <EmptyState icon="file" text={t("prices.receiptNotFound")} />
      </>
    );

  const rename = async () => {
    const name = await prompt.ask(t("prices.renameStore"), t("prices.storeName"), receipt.store ?? "", "storefront");
    if (name === null) return;
    setBusy(true);
    try {
      await renameReceiptStore(receipt, name, book.records ?? []);
    } catch (e) {
      status.show("error", e instanceof ReceiptGoneError ? t("prices.receiptNotFound") : t("prices.renameFailed"));
    } finally {
      setBusy(false);
    }
  };

  const remove = async () => {
    const keep = await choice.ask();
    if (keep === null) return;
    setBusy(true);
    try {
      await deleteReceipt(receipt, book.records ?? [], keep);
      navigate("/prices", { replace: true });
    } catch {
      status.show("error", t("prices.deleteFailed"));
      setBusy(false);
    }
  };

  if (phone) {
    return (
      <>
        <PhoneBar
          title={t("prices.receipts")}
          back="/prices"
          trailing={<ClayIconButton icon="delete_outline" label={t("prices.deleteReceipt")} onClick={() => void remove()} disabled={busy} />}
        />
        <PageHeader
          title={receipt.store ?? "—"}
          subtitle={`${date(receipt.purchasedAt)} · \u2066${priceLabel(receipt.total, receipt.currency)}\u2069`}
          trailing={<ClayIconButton icon="edit" size={44} label={t("prices.renameStore")} onClick={() => void rename()} disabled={busy} />}
        />
        {receiptHasImages(receipt) ? (
          <div className="mt-4">
            <Notice kind="info">{t("prices.imagesOnDevice")}</Notice>
          </div>
        ) : null}
        <ClayCard radius={24} padding={16} as="section" className="mt-4" aria-labelledby="captured-title">
          <h2 id="captured-title" className="border-b border-surface-highest pb-2 text-headline-md">
            {t("prices.captured")}
          </h2>
          {lines.length === 0 ? (
            <p className="pt-3 text-body-md text-on-surface-variant">{t("prices.noPrices")}</p>
          ) : (
            <ul className="pt-3">
              {lines.map((line) => (
                <li key={line.id}>
                  <button type="button" onClick={() => setEditing(line)} className="press flex w-full items-center gap-3 rounded-[8px] py-2 text-start" aria-label={t("prices.editLine", { name: line.name })}>
                    <span className="min-w-0 flex-1">
                      <span className="block text-body-md text-on-surface">{line.name}</span>
                      {printedNameOf(line) !== line.name ? <span className="block text-label-sm text-on-surface-variant">{t("prices.printedAs", { name: printedNameOf(line) })}</span> : null}
                    </span>
                    <span className="shrink-0 text-label-md text-on-surface-variant">
                      <span>
                        {formatAmount(line.quantity)} × {priceLabel(line.unitPrice, line.currency)}
                      </span>{" "}
                      {unitLabel(line.unit)}
                    </span>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </ClayCard>
        <AddPriceDialog
          open={editing !== null}
          initial={{ name: editing?.name, price: editing?.unitPrice, unit: editing?.unit }}
          onDone={(saved) => {
            setEditing(null);
            if (saved) status.show("success", t("prices.priceSaved"));
          }}
        />
        {prompt.element}
        {choice.element}
        {status.element}
      </>
    );
  }

  return (
    <>
      {back}
      <header className="mb-5 flex flex-wrap items-start gap-3">
        <div className="min-w-0 flex-1">
          <h1 className="text-headline-lg">{receipt.store ?? "—"}</h1>
          <p className="mt-1 text-body-md text-on-surface-variant">
            {date(receipt.purchasedAt)} · <span dir="ltr">{priceLabel(receipt.total, receipt.currency)}</span>
          </p>
        </div>
        <IconButton icon="edit" label={t("prices.renameStore")} onClick={() => void rename()} busy={busy} />
        <IconButton icon="trash" tone="danger" label={t("prices.deleteReceipt")} onClick={() => void remove()} disabled={busy} />
      </header>

      {receiptHasImages(receipt) ? (
        <div className="mb-4">
          <Notice kind="info">{t("prices.imagesOnDevice")}</Notice>
        </div>
      ) : null}

      <section className="clay p-5" aria-labelledby="captured-title">
        <h2 id="captured-title" className="mb-3 text-headline-md">
          {t("prices.captured")}
        </h2>
        {lines.length === 0 ? (
          <p className="text-on-surface-variant">{t("prices.noPrices")}</p>
        ) : (
          <ul className="grid gap-x-6 divide-y divide-outline-variant/40 md:grid-cols-2 md:divide-y-0">
            {lines.map((line) => (
              <li key={line.id}>
                <button type="button" onClick={() => setEditing(line)} className="flex w-full items-center gap-3 rounded-std px-2 py-2.5 text-start hover:bg-surface-low" aria-label={t("prices.editLine", { name: line.name })}>
                  <span className="min-w-0 flex-1">
                    <span className="block text-body-md">{line.name}</span>
                    {printedNameOf(line) !== line.name ? <span className="block text-label-sm text-on-surface-variant">{t("prices.printedAs", { name: printedNameOf(line) })}</span> : null}
                  </span>
                  <span className="text-label-md text-on-surface-variant">
                    <span dir="ltr">
                      {formatAmount(line.quantity)} × {priceLabel(line.unitPrice, line.currency)}
                    </span>{" "}
                    {unitLabel(line.unit)}
                  </span>
                </button>
              </li>
            ))}
          </ul>
        )}
      </section>

      <AddPriceDialog
        open={editing !== null}
        initial={{ name: editing?.name, price: editing?.unitPrice, unit: editing?.unit }}
        onDone={(saved) => {
          setEditing(null);
          if (saved) status.show("success", t("prices.priceSaved"));
        }}
      />
      {prompt.element}
      {choice.element}
      {status.element}
    </>
  );
}
