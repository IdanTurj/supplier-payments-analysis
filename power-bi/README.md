# Power BI dashboard plan

This folder is reserved for the Power BI reporting layer of the Supplier Payments Analysis project.

## Recommended data model

Connect Power BI to PostgreSQL and use the following reporting views:

- `vw_payment_detail`
- `vw_supplier_payment_summary`
- `vw_monthly_payment_summary`

The transaction-level view should be the main fact table for slicers and detailed visuals. The supplier and monthly views provide pre-aggregated reporting outputs for validation and comparison.

## Recommended KPI cards

- Total Payment Value
- Total Paid
- Total Pending
- Paid Transaction Rate
- Total Transactions

## Recommended visuals

1. **Payments by Status** — clustered column or donut chart using transaction count or payment value.
2. **Paid vs. Pending by Supplier** — clustered bar chart with supplier on the axis.
3. **Monthly Payment Trend** — line and clustered column chart showing total paid and pending by month.
4. **Outstanding Payments by Supplier** — descending bar chart based on total pending amount.
5. **Supplier Performance Table** — supplier, total transactions, total paid, total pending, paid %, average payment, and largest payment.
6. **Payment Size Distribution** — chart using Small / Medium / Large segments.

## Recommended slicers

- Supplier Name
- Status
- Payment Date
- Payment Size

## Suggested DAX measures

```DAX
Total Payment Value =
SUM(vw_payment_detail[amount])

Total Paid =
CALCULATE(
    SUM(vw_payment_detail[amount]),
    vw_payment_detail[status] = "paid"
)

Total Pending =
CALCULATE(
    SUM(vw_payment_detail[amount]),
    vw_payment_detail[status] = "pending"
)

Total Transactions =
COUNTROWS(vw_payment_detail)

Paid Transactions =
CALCULATE(
    COUNTROWS(vw_payment_detail),
    vw_payment_detail[status] = "paid"
)

Paid Transaction Rate =
DIVIDE([Paid Transactions], [Total Transactions], 0)
```

## Portfolio presentation

When the dashboard is complete, export or capture a clean dashboard screenshot and save it in the repository `assets/` folder. The main README can then display the Power BI dashboard near the top of the project page.
