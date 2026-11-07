/**
 * MIT 8103: Advanced Database Systems - Portfolio 4
 * Student Name: Peace Ekoh | Student ID: 301866431
 * Case Study: NovaMart Retail Logistics & Storefront
 * File: mongodb_queries.js
 * Engine: MongoDB Document Model / Aggregation Pipeline
 */

// ============================================================================
// 1. COLLECTION CREATION & INDEXING
// ============================================================================
use('novamart_nosql');

// Create Compound and Multikey Indexes for fast catalog browsing
db.products.createIndex({ "category.primary": 1, "pricing.final_price": 1 });
db.products.createIndex({ "tags": 1 }); // Multikey index on tags array
db.products.createIndex({ "specifications.ram_gb": 1 }); // Sparse index on polymorphic attribute
db.products.createIndex({ "review_summary.average_rating": -1 });


// ============================================================================
// 2. POLYMORPHIC ATTRIBUTE FILTERING (Demonstrates Document Flexibility)
// Query: Find all laptops with at least 16GB RAM and price <= 3,000,000 NGN
// Note: In Relational SQL, this requires complex EAV joins; in NoSQL, dot-notation handles it in O(1)
// ============================================================================
db.products.find(
  {
    "category.sub_category": "Laptops & Computers",
    "specifications.ram_gb": { $gte: 16 },
    "pricing.final_price": { $lte: 3000000 }
  },
  {
    "product_name": 1,
    "brand": 1,
    "pricing.final_price": 1,
    "specifications.processor": 1,
    "specifications.ram_gb": 1,
    "inventory.available_stock": 1
  }
).sort({ "pricing.final_price": -1 });


// ============================================================================
// 3. FACETED TAG & FULL-TEXT SEARCH
// Query: Search for flagship electronics tagged with 'titanium' or 'm3-max'
// ============================================================================
db.products.find(
  {
    "category.primary": "Electronics",
    "tags": { $in: ["titanium", "m3-max"] },
    "review_summary.average_rating": { $gte: 4.5 }
  },
  {
    "product_name": 1,
    "brand": 1,
    "tags": 1,
    "review_summary": 1
  }
);


// ============================================================================
// 4. ATOMIC EMBEDDED DOCUMENT UPDATE ($push and $inc)
// Business Action: Customer leaves a 5-star review on the iPhone 15 Pro.
// We atomically append the review to the embedded array and recalculate metrics.
// ============================================================================
db.products.updateOne(
  { "_id": "PROD-TECH-001" },
  {
    $push: {
      "reviews": {
        "review_id": "REV-104",
        "customer_id": 8,
        "customer_name": "Zainab Dahiru",
        "rating": 5,
        "title": "Camera in low light is mind blowing",
        "comment": "Night mode portraits are crystal clear without artificial grain.",
        "verified_purchase": true,
        "helpful_votes": 0,
        "created_at": new Date().toISOString()
      }
    },
    $inc: {
      "review_summary.total_reviews": 1
    },
    $set: {
      "review_summary.average_rating": 4.85,
      "updated_at": new Date().toISOString()
    }
  }
);


// ============================================================================
// 5. AGGREGATION PIPELINE: Category Performance & Customer Satisfaction
// Pipeline: Groups products by primary category and calculates total catalog count,
//           average customer rating, and total customer review engagement.
// ============================================================================
db.products.aggregate([
  {
    $project: {
      "category": "$category.primary",
      "rating": "$review_summary.average_rating",
      "review_count": "$review_summary.total_reviews",
      "stock": "$inventory.available_stock"
    }
  },
  {
    $group: {
      "_id": "$category",
      "total_catalog_products": { $sum: 1 },
      "category_avg_rating": { $avg: "$rating" },
      "total_customer_reviews": { $sum: "$review_count" },
      "total_warehouse_stock": { $sum: "$stock" }
    }
  },
  {
    $project: {
      "category": "$_id",
      "_id": 0,
      "total_catalog_products": 1,
      "category_avg_rating": { $round: ["$category_avg_rating", 2] },
      "total_customer_reviews": 1,
      "total_warehouse_stock": 1
    }
  },
  {
    $sort: { "category_avg_rating": -1 }
  }
]);


// ============================================================================
// 6. ADVANCED AGGREGATION: $unwind Review Sentiment & Verified Buyer Breakdown
// Pipeline: Unwinds embedded reviews array to calculate proportion of verified 
//           vs. non-verified reviews and distribution of 5-star ratings.
// ============================================================================
db.products.aggregate([
  { $unwind: "$reviews" },
  {
    $group: {
      _id: {
        category: "$category.primary",
        verified_buyer: "$reviews.verified_purchase"
      },
      review_count: { $sum: 1 },
      average_rating: { $avg: "$reviews.rating" },
      five_star_reviews: {
        $sum: { $cond: [{ $eq: ["$reviews.rating", 5] }, 1, 0] }
      }
    }
  },
  {
    $project: {
      _id: 0,
      category: "$_id.category",
      verified_buyer: "$_id.verified_buyer",
      review_count: 1,
      average_rating: { $round: ["$average_rating", 2] },
      five_star_reviews: 1
    }
  },
  { $sort: { category: 1, verified_buyer: -1 } }
]);


// ============================================================================
// 7. REDIS KEY-VALUE MODEL (Shopping Cart & Real-Time Stock Cache)
// Example Redis CLI Commands for session state management:
// ============================================================================

/*
# Store ephemeral user shopping cart with 7-day TTL (Time-To-Live)
HSET cart:session:cust_001 "PROD-TECH-001" 1
HSET cart:session:cust_001 "PROD-GROC-001" 2
EXPIRE cart:session:cust_001 604800

# Fast in-memory atomic inventory check before hitting MySQL
SET stock:cache:PROD-TECH-001 24
DECRBY stock:cache:PROD-TECH-001 1
*/
