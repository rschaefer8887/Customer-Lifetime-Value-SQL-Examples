"""Generate realistic DTC marketing sample data for the SQL portfolio."""
from __future__ import annotations

import csv
import random
from datetime import date, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
RNG = random.Random(42)

# Dimension: marketing channel of acquisition
MARKETING_CHANNELS = [
    {"channel_id": 1, "channel_name": "Direct Mail", "channel_code": "direct_mail"},
    {"channel_id": 2, "channel_name": "Paid Social", "channel_code": "paid_social"},
    {"channel_id": 3, "channel_name": "Email", "channel_code": "email"},
    {"channel_id": 4, "channel_name": "Organic", "channel_code": "organic"},
    {"channel_id": 5, "channel_name": "Direct", "channel_code": "direct"},
]

CHANNEL_BY_CODE = {c["channel_code"]: c for c in MARKETING_CHANNELS}

# Acquisition mix weights (aligned to channel_id order above)
CHANNEL_WEIGHTS = [22, 28, 16, 18, 16]

REBUY_P = {
    "direct_mail": 0.55,
    "paid_social": 0.34,
    "email": 0.45,
    "organic": 0.38,
    "direct": 0.36,
}


def daterange(start: date, end: date):
    d = start
    while d <= end:
        yield d
        d += timedelta(days=1)


def month_start(d: date) -> date:
    return date(d.year, d.month, 1)


def build_months(start: date, end: date) -> list[dict]:
    """One row per calendar month from start..end (inclusive by month)."""
    rows = []
    y, m = start.year, start.month
    month_id = 1
    while date(y, m, 1) <= end:
        ms = date(y, m, 1)
        if m == 12:
            me = date(y, 12, 31)
            y, m = y + 1, 1
        else:
            me = date(y, m + 1, 1) - timedelta(days=1)
            m += 1
        rows.append(
            {
                "month_id": month_id,
                "month_start": ms.isoformat(),
                "month_end": me.isoformat(),
                "year": ms.year,
                "month_number": ms.month,
                "month_label": ms.strftime("%Y-%m"),
            }
        )
        month_id += 1
    return rows


def write_csv(path: Path, rows: list[dict], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        w.writerows(rows)


def make_order(
    order_id: int,
    customer_id: int,
    order_date: date,
    gross_revenue: float,
    is_size_exchange: int,
    order_channel_id: int,
) -> dict:
    # COGS roughly 40-55% of revenue; exchanges keep a small residual cost
    if is_size_exchange:
        cogs_ratio = RNG.uniform(0.55, 0.75)
    else:
        cogs_ratio = RNG.uniform(0.38, 0.55)
    cogs = round(gross_revenue * cogs_ratio, 2)
    return {
        "order_id": order_id,
        "customer_id": customer_id,
        "order_date": order_date.isoformat(),
        "gross_revenue": gross_revenue,
        "cogs": cogs,
        "is_size_exchange": is_size_exchange,
        "order_channel_id": order_channel_id,
    }


def main() -> None:
    start = date(2023, 1, 1)
    end = date(2024, 12, 31)

    months = build_months(start, end)
    month_id_by_start = {r["month_start"]: r["month_id"] for r in months}
    write_csv(
        DATA / "months.csv",
        months,
        ["month_id", "month_start", "month_end", "year", "month_number", "month_label"],
    )

    write_csv(
        DATA / "marketing_channels.csv",
        MARKETING_CHANNELS,
        ["channel_id", "channel_name", "channel_code"],
    )

    customers = []
    orders = []
    mail_assignments = []
    meta_spend = []
    order_id = 1

    codes = [c["channel_code"] for c in MARKETING_CHANNELS]

    for i in range(1, 2501):
        acq_offset = RNG.randint(0, (end - start).days - 60)
        first_order = start + timedelta(days=acq_offset)
        channel_code = RNG.choices(codes, weights=CHANNEL_WEIGHTS, k=1)[0]
        channel = CHANNEL_BY_CODE[channel_code]
        acq_month_start = month_start(first_order).isoformat()

        # Within Paid Social, track buyer_file vs acquisition campaign subtype
        if channel_code == "paid_social":
            social_subtype = "buyer_file" if RNG.random() < 0.40 else "acquisition"
            utm = f"meta_{social_subtype}_{first_order.strftime('%Y_%m')}"
        else:
            social_subtype = ""
            utm = f"{channel_code}_{first_order.strftime('%Y_%m')}"

        customers.append(
            {
                "customer_id": i,
                "first_order_date": first_order.isoformat(),
                "acquisition_channel_id": channel["channel_id"],
                "acquisition_month_id": month_id_by_start[acq_month_start],
                "acquisition_channel_code": channel_code,
                "paid_social_subtype": social_subtype,
                "acquisition_utm_campaign": utm,
            }
        )

        rev = round(RNG.uniform(45, 220), 2)
        is_exchange = 1 if RNG.random() < 0.04 else 0
        gross = rev if not is_exchange else round(rev * 0.3, 2)
        orders.append(
            make_order(order_id, i, first_order, gross, is_exchange, channel["channel_id"])
        )
        order_id += 1

        rebuy_p = REBUY_P[channel_code]
        if channel_code == "paid_social" and social_subtype == "acquisition":
            rebuy_p = 0.28
        elif channel_code == "paid_social" and social_subtype == "buyer_file":
            rebuy_p = 0.48
        if first_order >= date(2024, 6, 1):
            rebuy_p *= 0.75

        n_rebuy = RNG.randint(1, 3) if RNG.random() < rebuy_p else 0
        for _ in range(n_rebuy):
            gap = RNG.randint(30, 280)
            od = first_order + timedelta(days=gap)
            if od > end:
                break
            rebuy_channel = RNG.choice(
                [channel_code, "email", "direct_mail", "organic", "direct"]
            )
            orders.append(
                make_order(
                    order_id,
                    i,
                    od,
                    round(RNG.uniform(40, 260), 2),
                    0,
                    CHANNEL_BY_CODE[rebuy_channel]["channel_id"],
                )
            )
            order_id += 1

    for drop_id, drop_date, audience in [
        ("dm_2024_spring_buyer", date(2024, 3, 15), "buyer_file"),
        ("dm_2024_spring_prospect", date(2024, 3, 15), "prospect"),
        ("dm_2024_fall_buyer", date(2024, 9, 10), "buyer_file"),
        ("dm_2024_fall_prospect", date(2024, 9, 10), "prospect"),
    ]:
        if audience == "buyer_file":
            pool = [
                c
                for c in customers
                if date.fromisoformat(c["first_order_date"]) < drop_date - timedelta(days=90)
            ]
        else:
            pool = [{"customer_id": 90000 + j} for j in range(1, 401)]

        sample = RNG.sample(pool, k=min(400, len(pool)))
        for row in sample:
            cid = row["customer_id"]
            treated = 1 if RNG.random() < 0.80 else 0
            mail_assignments.append(
                {
                    "drop_id": drop_id,
                    "drop_date": drop_date.isoformat(),
                    "audience_type": audience,
                    "customer_id": cid,
                    "is_mailed": treated,
                }
            )
            if treated and RNG.random() < (0.12 if audience == "buyer_file" else 0.06):
                od = drop_date + timedelta(days=RNG.randint(3, 45))
                if od <= end:
                    orders.append(
                        make_order(
                            order_id,
                            cid,
                            od,
                            round(RNG.uniform(50, 180), 2),
                            0,
                            CHANNEL_BY_CODE["direct_mail"]["channel_id"],
                        )
                    )
                    order_id += 1
                    if audience == "prospect" and cid >= 90000:
                        if not any(c["customer_id"] == cid for c in customers):
                            acq_month_start = month_start(od).isoformat()
                            customers.append(
                                {
                                    "customer_id": cid,
                                    "first_order_date": od.isoformat(),
                                    "acquisition_channel_id": CHANNEL_BY_CODE["direct_mail"][
                                        "channel_id"
                                    ],
                                    "acquisition_month_id": month_id_by_start[acq_month_start],
                                    "acquisition_channel_code": "direct_mail",
                                    "paid_social_subtype": "",
                                    "acquisition_utm_campaign": drop_id,
                                }
                            )
            elif (not treated) and RNG.random() < (0.05 if audience == "buyer_file" else 0.02):
                od = drop_date + timedelta(days=RNG.randint(3, 45))
                if od <= end:
                    orders.append(
                        make_order(
                            order_id,
                            cid,
                            od,
                            round(RNG.uniform(50, 180), 2),
                            0,
                            CHANNEL_BY_CODE["organic"]["channel_id"],
                        )
                    )
                    order_id += 1

    # Daily Paid Social detail (buyer_file vs acquisition) for both years
    for d in daterange(start, end):
        for ctype, base in [("buyer_file", 800), ("acquisition", 1200)]:
            meta_spend.append(
                {
                    "spend_date": d.isoformat(),
                    "campaign_type": ctype,
                    "utm_campaign": f"meta_{ctype}_{d.strftime('%Y_%m')}",
                    "spend": round(base * RNG.uniform(0.7, 1.3), 2),
                    "platform_reported_purchases": RNG.randint(5, 40),
                }
            )

    # Monthly spend by marketing channel (all months 2023-2024).
    # Direct and Organic are unpaid: spend = 0.
    paid_monthly_base = {
        "direct_mail": 55000,
        "paid_social": 62000,
        "email": 9000,
        "organic": 0,
        "direct": 0,
    }
    channel_monthly_spend = []
    for mrow in months:
        # Mild seasonality: higher in Q4, lower in Jan/Feb
        month_num = int(mrow["month_number"])
        season = 1.25 if month_num in (10, 11, 12) else (0.85 if month_num in (1, 2) else 1.0)
        for ch in MARKETING_CHANNELS:
            code = ch["channel_code"]
            base = paid_monthly_base[code]
            if base == 0:
                spend = 0.0
            else:
                spend = round(base * season * RNG.uniform(0.85, 1.15), 2)
            channel_monthly_spend.append(
                {
                    "month_id": mrow["month_id"],
                    "month_label": mrow["month_label"],
                    "channel_id": ch["channel_id"],
                    "channel_name": ch["channel_name"],
                    "channel_code": code,
                    "spend": spend,
                }
            )

    write_csv(
        DATA / "customers.csv",
        customers,
        [
            "customer_id",
            "first_order_date",
            "acquisition_channel_id",
            "acquisition_month_id",
            "acquisition_channel_code",
            "paid_social_subtype",
            "acquisition_utm_campaign",
        ],
    )
    write_csv(
        DATA / "orders.csv",
        orders,
        [
            "order_id",
            "customer_id",
            "order_date",
            "gross_revenue",
            "cogs",
            "is_size_exchange",
            "order_channel_id",
        ],
    )
    write_csv(
        DATA / "mail_assignments.csv",
        mail_assignments,
        ["drop_id", "drop_date", "audience_type", "customer_id", "is_mailed"],
    )
    write_csv(
        DATA / "meta_spend.csv",
        meta_spend,
        ["spend_date", "campaign_type", "utm_campaign", "spend", "platform_reported_purchases"],
    )
    write_csv(
        DATA / "channel_monthly_spend.csv",
        channel_monthly_spend,
        [
            "month_id",
            "month_label",
            "channel_id",
            "channel_name",
            "channel_code",
            "spend",
        ],
    )
    print(f"Wrote sample data to {DATA}")
    print(f"  months: {len(months)}")
    print(f"  marketing_channels: {len(MARKETING_CHANNELS)}")
    print(f"  customers: {len(customers)}")
    print(f"  orders: {len(orders)}")
    print(f"  mail_assignments: {len(mail_assignments)}")
    print(f"  meta_spend rows: {len(meta_spend)}")
    print(f"  channel_monthly_spend: {len(channel_monthly_spend)}")


if __name__ == "__main__":
    main()
