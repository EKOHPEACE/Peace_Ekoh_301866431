# ============================================================================
# MIT 8103: Advanced Database Systems - Portfolio 4
# Student Name: Peace Ekoh | Student ID: 301866431
# Case Study: NovaMart Retail Logistics & Storefront
# Script: run_nosql_demo.py
# Purpose: Simulates MongoDB Document Store execution engine (CRUD & Aggregation)
#          using the NovaMart polymorphic product catalog and customer reviews.
# ============================================================================

import json
from pathlib import Path
from datetime import datetime

def load_catalog():
    data_path = Path(__file__).parent / "nosql_model.json"
    with open(data_path, "r", encoding="utf-8") as f:
        return json.load(f)

def demo_polymorphic_filtering(catalog):
    print("\n" + "=" * 75)
    print("DEMO 1: POLYMORPHIC ATTRIBUTE FILTERING (Laptops with RAM >= 16GB)")
    print("=" * 75)
    matches = []
    for item in catalog:
        subcat = item.get("category", {}).get("sub_category", "")
        ram = item.get("specifications", {}).get("ram_gb", 0)
        price = item.get("pricing", {}).get("final_price", 0)
        if subcat == "Laptops & Computers" and ram >= 16 and price <= 3000000:
            matches.append(item)
    
    for m in matches:
        specs = m["specifications"]
        print(f"Product: {m['product_name']} ({m['brand']})")
        print(f"  Price: NGN {m['pricing']['final_price']:,.2f}")
        print(f"  Specs: RAM={specs.get('ram_gb')}GB | CPU={specs.get('processor')} | Storage={specs.get('storage_gb')}GB")
        print(f"  Stock: {m['inventory']['available_stock']} units available")

def demo_faceted_search(catalog):
    print("\n" + "=" * 75)
    print("DEMO 2: FACETED TAG & RATING SEARCH (Electronics with 'titanium' or 'm3-max')")
    print("=" * 75)
    matches = [
        item for item in catalog
        if item.get("category", {}).get("primary") == "Electronics"
        and any(tag in ["titanium", "m3-max"] for tag in item.get("tags", []))
        and item.get("review_summary", {}).get("average_rating", 0) >= 4.5
    ]
    for m in matches:
        print(f"Product: {m['product_name']} | Rating: {m['review_summary']['average_rating']} Stars | Tags: {m['tags']}")

def demo_embedded_review_update(catalog):
    print("\n" + "=" * 75)
    print("DEMO 3: ATOMIC EMBEDDED REVIEW UPDATE ($push and $inc simulation)")
    print("=" * 75)
    target = next((item for item in catalog if item["_id"] == "PROD-TECH-001"), None)
    if target:
        print(f"Before Update: Reviews Count = {target['review_summary']['total_reviews']}, Avg Rating = {target['review_summary']['average_rating']}")
        
        new_review = {
            "review_id": "REV-104",
            "customer_id": 8,
            "customer_name": "Zainab Dahiru",
            "rating": 5.0,
            "title": "Camera in low light is mind blowing",
            "comment": "Night mode portraits are crystal clear without artificial grain.",
            "verified_purchase": True,
            "helpful_votes": 0,
            "created_at": datetime.now().isoformat()
        }
        
        target["reviews"].append(new_review)
        target["review_summary"]["total_reviews"] += 1
        all_ratings = [r["rating"] for r in target["reviews"]]
        target["review_summary"]["average_rating"] = round(sum(all_ratings) / len(all_ratings), 2)
        target["updated_at"] = datetime.now().isoformat()
        
        print(f"After  Update: Reviews Count = {target['review_summary']['total_reviews']}, Avg Rating = {target['review_summary']['average_rating']}")
        print(f"Newly Appended Review: \"{new_review['title']}\" by {new_review['customer_name']} (Rating: {new_review['rating']} Stars)")

def demo_aggregation_pipeline(catalog):
    print("\n" + "=" * 75)
    print("DEMO 4: MONGODB AGGREGATION PIPELINE (Category Satisfaction & Stock Metrics)")
    print("=" * 75)
    groups = {}
    for item in catalog:
        cat = item.get("category", {}).get("primary", "Other")
        if cat not in groups:
            groups[cat] = {"count": 0, "ratings": [], "reviews": 0, "stock": 0}
        groups[cat]["count"] += 1
        groups[cat]["ratings"].append(item.get("review_summary", {}).get("average_rating", 0))
        groups[cat]["reviews"] += item.get("review_summary", {}).get("total_reviews", 0)
        groups[cat]["stock"] += item.get("inventory", {}).get("available_stock", 0)
    
    results = []
    for cat, data in groups.items():
        avg_rating = round(sum(data["ratings"]) / len(data["ratings"]), 2)
        results.append({
            "category": cat,
            "catalog_items": data["count"],
            "avg_customer_rating": avg_rating,
            "total_reviews": data["reviews"],
            "total_inventory": data["stock"]
        })
    
    results.sort(key=lambda x: x["avg_customer_rating"], reverse=True)
    
    print(f"{'Category':<25} | {'Items':<6} | {'Avg Rating':<11} | {'Total Reviews':<13} | {'Stock Units'}")
    print("-" * 75)
    for r in results:
        print(f"{r['category']:<25} | {r['catalog_items']:<6} | {r['avg_customer_rating']:<11} | {r['total_reviews']:<13} | {r['total_inventory']}")

def demo_unwind_review_sentiment(catalog):
    print("\n" + "=" * 75)
    print("DEMO 5: ARRAY UNWIND & VERIFIED BUYER SATISFACTION ($unwind Simulation)")
    print("=" * 75)
    all_reviews = []
    for item in catalog:
        cat = item.get("category", {}).get("primary", "Other")
        for r in item.get("reviews", []):
            all_reviews.append({
                "category": cat,
                "rating": r.get("rating", 0),
                "verified": r.get("verified_purchase", False)
            })
    
    groups = {}
    for r in all_reviews:
        key = (r["category"], r["verified"])
        if key not in groups:
            groups[key] = {"count": 0, "ratings": [], "five_stars": 0}
        groups[key]["count"] += 1
        groups[key]["ratings"].append(r["rating"])
        if r["rating"] == 5.0:
            groups[key]["five_stars"] += 1
            
    print(f"{'Category':<24} | {'Buyer Status':<16} | {'Reviews':<8} | {'Avg Rating':<11} | {'5-Star %'}")
    print("-" * 75)
    for (cat, ver), data in sorted(groups.items(), key=lambda x: (x[0][0], not x[0][1])):
        b_type = "Verified Buyer" if ver else "Unverified"
        avg_r = round(sum(data["ratings"]) / len(data["ratings"]), 2)
        pct = f"{round((data['five_stars'] / data['count']) * 100)}%"
        print(f"{cat:<24} | {b_type:<16} | {data['count']:<8} | {avg_r:<11} | {pct}")

def demo_redis_sorted_set_leaderboard():
    print("\n" + "=" * 75)
    print("DEMO 6: REDIS IN-MEMORY BEST-SELLER LEADERBOARD (Sorted Set - ZSET Simulation)")
    print("=" * 75)
    # Simulated atomic ZINCRBY updates upon order completion
    leaderboard = {
        "PROD-GROC-001": {"name": "Golden Penny Pure Soya Oil (5L)", "units_sold": 18},
        "PROD-TECH-002": {"name": "Apple MacBook Pro 14 M3 Max", "units_sold": 12},
        "PROD-TECH-001": {"name": "Apple iPhone 15 Pro", "units_sold": 5},
        "PROD-FASH-001": {"name": "Men's Italian Tailored Wool Suit", "units_sold": 3}
    }
    
    # Sort descending by score O(log N)
    ranked = sorted(leaderboard.items(), key=lambda x: x[1]["units_sold"], reverse=True)
    
    print(f"{'Rank':<6} | {'SKU':<15} | {'Product Name':<35} | {'Score (Units Sold)'}")
    print("-" * 75)
    for rank, (sku, data) in enumerate(ranked, start=1):
        print(f"#{rank:<5} | {sku:<15} | {data['name']:<35} | {data['units_sold']}")
    print("-" * 75)
    print("Command Verification: ZREVRANGE leaderboard:bestsellers:2026-11 0 2 WITHSCORES")
    print(f"Top Trending Item: {ranked[0][0]} with {ranked[0][1]['units_sold']} units sold (Score).")

if __name__ == "__main__":
    print("=" * 75)
    print("NOVAMART NOSQL DOCUMENT STORE ENGINE VERIFICATION (MongoDB Simulation)")
    print("Dataset: Polymorphic E-Commerce Catalog & Embedded Customer Reviews")
    print("=" * 75)
    
    catalog = load_catalog()
    demo_polymorphic_filtering(catalog)
    demo_faceted_search(catalog)
    demo_embedded_review_update(catalog)
    demo_aggregation_pipeline(catalog)
    demo_unwind_review_sentiment(catalog)
    demo_redis_sorted_set_leaderboard()

