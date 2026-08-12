"""Generate realistic DTC marketing sample data for the SQL portfolio."""
from __future__ import annotations

import csv
import random
from datetime import date, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
RNG = random.Random(42)

CHANNELS = [
    "direct_mail",
    "paid_search_brand",
    "paid_search_nonbrand",
    "meta_buyer_file",
    "meta_acquisition",
    "email",
    "organic",
]


def daterange(start: date, end: date):
    d = start
    while d <= end:
        yield d
        d += timedelta(days=1)


def write_csv(path: Path, rows: list[dict], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        w.writerows(rows)


def main() -> None:
    start = date(2023, 1, 1)
    end = date(2024, 12, 31)

    customers = []
    orders = []
    mail_assignments = []
    meta_spend = []
    order_id = 1

    # ~2500 customers across acquisition months
    for i in range(1, 2501):
        acq_offset = RNG.randint(0, (end - start).days - 60)
        first_order = start + timedelta(days=acq_offset)
        channel = RNG.choices(
            CHANNELS,
            weights=[22, 10, 14, 12, 16, 14, 12],
            k=1,
        )[0]
        customers.append(
            {
                "customer_id": i,
                "first_order_date": first_order.isoformat(),
                "acquisition_channel": channel,
                "acquisition_utm_campaign": f"{channel}_{first_order.strftime('%Y_%m')}",
            }
        )

        # First order
        rev = round(RNG.uniform(45, 220), 2)
        is_exchange = 1 if RNG.random() < 0.04 else 0
        orders.append(
            {
                "order_id": order_id,
                "customer_id": i,
                "order_date": first_order.isoformat(),
                "gross_revenue": rev if not is_exchange else round(rev * 0.3, 2),
                "is_size_exchange": is_exchange,
                "order_channel": channel,
            }
        )
        order_id += 1

        # Rebuy probability by channel quality
        rebuy_p = {
            "direct_mail": 0.55,
            "paid_search_brand": 0.40,
            "paid_search_nonbrand": 0.32,
            "meta_buyer_file": 0.48,
            "meta_acquisition": 0.28,
            "email": 0.45,
            "organic": 0.38,
        }[channel]
        # Later cohorts slightly weaker (for Buyer File Health demos)
        if first_order >= date(2024, 6, 1):
            rebuy_p *= 0.75

        n_rebuy = 0
        if RNG.random() < rebuy_p:
            n_rebuy = RNG.randint(1, 3)
        for _ in range(n_rebuy):
            gap = RNG.randint(30, 280)
            od = first_order + timedelta(days=gap)
            if od > end:
                break
            orders.append(
                {
                    "order_id": order_id,
                    "customer_id": i,
                    "order_date": od.isoformat(),
                    "gross_revenue": round(RNG.uniform(40, 260), 2),
                    "is_size_exchange": 0,
                    "order_channel": RNG.choice(["email", "direct_mail", "organic", channel]),
                }
            )
            order_id += 1

    # Direct Mail holdout test: pick buyer-file and prospect pools for two drops
    for drop_id, drop_date, audience in [
        ("dm_2024_spring_buyer", date(2024, 3, 15), "buyer_file"),
        ("dm_2024_spring_prospect", date(2024, 3, 15), "prospect"),
        ("dm_2024_fall_buyer", date(2024, 9, 10), "buyer_file"),
        ("dm_2024_fall_prospect", date(2024, 9, 10), "prospect"),
    ]:
        if audience == "buyer_file":
            pool = [c for c in customers if date.fromisoformat(c["first_order_date"]) < drop_date - timedelta(days=90)]
        else:
            # Prospects: invent IDs 90000+
            pool = [{"customer_id": 90000 + j, "is_prospect": True} for j in range(1, 401)]

        sample = RNG.sample(pool, k=min(400, len(pool)))
        for row in sample:
            cid = row["customer_id"]
            treated = 1 if RNG.random() < 0.80 else 0  # 80% mailed, 20% holdout
            mail_assignments.append(
                {
                    "drop_id": drop_id,
                    "drop_date": drop_date.isoformat(),
                    "audience_type": audience,
                    "customer_id": cid,
                    "is_mailed": treated,
                }
            )
            # Incremental purchase lift for mailed
            if treated and RNG.random() < (0.12 if audience == "buyer_file" else 0.06):
                od = drop_date + timedelta(days=RNG.randint(3, 45))
                if od <= end:
                    orders.append(
                        {
                            "order_id": order_id,
                            "customer_id": cid,
                            "order_date": od.isoformat(),
                            "gross_revenue": round(RNG.uniform(50, 180), 2),
                            "is_size_exchange": 0,
                            "order_channel": "direct_mail",
                        }
                    )
                    order_id += 1
                    if audience == "prospect" and cid >= 90000:
                        # New customer from prospect mail
                        if not any(c["customer_id"] == cid for c in customers):
                            customers.append(
                                {
                                    "customer_id": cid,
                                    "first_order_date": od.isoformat(),
                                    "acquisition_channel": "direct_mail",
                                    "acquisition_utm_campaign": drop_id,
                                }
                            )
            elif (not treated) and RNG.random() < (0.05 if audience == "buyer_file" else 0.02):
                # Baseline conversion in holdout
                od = drop_date + timedelta(days=RNG.randint(3, 45))
                if od <= end:
                    orders.append(
                        {
                            "order_id": order_id,
                            "customer_id": cid,
                            "order_date": od.isoformat(),
                            "gross_revenue": round(RNG.uniform(50, 180), 2),
                            "is_size_exchange": 0,
                            "order_channel": "organic",
                        }
                    )
                    order_id += 1

    # Daily Meta spend for buyer_file vs acquisition
    for d in daterange(date(2024, 1, 1), date(2024, 12, 31)):
        for ctype, base in [("buyer_file", 800), ("acquisition", 1200)]:
            spend = round(base * RNG.uniform(0.7, 1.3), 2)
            meta_spend.append(
                {
                    "spend_date": d.isoformat(),
                    "campaign_type": ctype,
                    "utm_campaign": f"meta_{ctype}_{d.strftime('%Y_%m')}",
                    "spend": spend,
                    "platform_reported_purchases": RNG.randint(5, 40),
                }
            )

    write_csv(
        DATA / "customers.csv",
        customers,
        ["customer_id", "first_order_date", "acquisition_channel", "acquisition_utm_campaign"],
    )
    write_csv(
        DATA / "orders.csv",
        orders,
        ["order_id", "customer_id", "order_date", "gross_revenue", "is_size_exchange", "order_channel"],
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
    print(f"Wrote sample data to {DATA}")
    print(f"  customers: {len(customers)}")
    print(f"  orders: {len(orders)}")
    print(f"  mail_assignments: {len(mail_assignments)}")
    print(f"  meta_spend rows: {len(meta_spend)}")


if __name__ == "__main__":
    main()
