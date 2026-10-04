-- Хелпер: пустая строка -> NULL
-- Порядок: листья -> city/supplier -> основные dims -> fact

INSERT INTO star.dim_country (country_name)
SELECT DISTINCT TRIM(c.country_name)
FROM (
    SELECT customer_country AS country_name FROM mock_data
    UNION ALL
    SELECT seller_country FROM mock_data
    UNION ALL
    SELECT store_country FROM mock_data
    UNION ALL
    SELECT supplier_country FROM mock_data
) c
WHERE NULLIF(TRIM(c.country_name), '') IS NOT NULL
ON CONFLICT (country_name) DO NOTHING;

INSERT INTO star.dim_pet_type (pet_type_name)
SELECT DISTINCT TRIM(customer_pet_type)
FROM mock_data
WHERE NULLIF(TRIM(customer_pet_type), '') IS NOT NULL
ON CONFLICT (pet_type_name) DO NOTHING;

INSERT INTO star.dim_pet_breed (breed_name)
SELECT DISTINCT TRIM(customer_pet_breed)
FROM mock_data
WHERE NULLIF(TRIM(customer_pet_breed), '') IS NOT NULL
ON CONFLICT (breed_name) DO NOTHING;

INSERT INTO star.dim_product_category (category_name)
SELECT DISTINCT TRIM(product_category)
FROM mock_data
WHERE NULLIF(TRIM(product_category), '') IS NOT NULL
ON CONFLICT (category_name) DO NOTHING;

INSERT INTO star.dim_pet_category (pet_category_name)
SELECT DISTINCT TRIM(pet_category)
FROM mock_data
WHERE NULLIF(TRIM(pet_category), '') IS NOT NULL
ON CONFLICT (pet_category_name) DO NOTHING;

INSERT INTO star.dim_brand (brand_name)
SELECT DISTINCT TRIM(product_brand)
FROM mock_data
WHERE NULLIF(TRIM(product_brand), '') IS NOT NULL
ON CONFLICT (brand_name) DO NOTHING;

INSERT INTO star.dim_color (color_name)
SELECT DISTINCT TRIM(product_color)
FROM mock_data
WHERE NULLIF(TRIM(product_color), '') IS NOT NULL
ON CONFLICT (color_name) DO NOTHING;

INSERT INTO star.dim_size (size_name)
SELECT DISTINCT TRIM(product_size)
FROM mock_data
WHERE NULLIF(TRIM(product_size), '') IS NOT NULL
ON CONFLICT (size_name) DO NOTHING;

INSERT INTO star.dim_material (material_name)
SELECT DISTINCT TRIM(product_material)
FROM mock_data
WHERE NULLIF(TRIM(product_material), '') IS NOT NULL
ON CONFLICT (material_name) DO NOTHING;

INSERT INTO star.dim_date (full_date, year_num, quarter_num, month_num, day_num, month_name)
SELECT DISTINCT
    d.full_date,
    EXTRACT(YEAR FROM d.full_date)::INTEGER,
    EXTRACT(QUARTER FROM d.full_date)::INTEGER,
    EXTRACT(MONTH FROM d.full_date)::INTEGER,
    EXTRACT(DAY FROM d.full_date)::INTEGER,
    TO_CHAR(d.full_date, 'Month')
FROM (
    SELECT TO_DATE(sale_date, 'MM/DD/YYYY') AS full_date
    FROM mock_data
    WHERE NULLIF(TRIM(sale_date), '') IS NOT NULL
) d
ON CONFLICT (full_date) DO NOTHING;

INSERT INTO star.dim_city (city_name, country_id)
SELECT DISTINCT
    TRIM(x.city_name),
    c.country_id
FROM (
    SELECT store_city AS city_name, store_country AS country_name FROM mock_data
    UNION ALL
    SELECT supplier_city, supplier_country FROM mock_data
) x
JOIN star.dim_country c ON c.country_name = TRIM(x.country_name)
WHERE NULLIF(TRIM(x.city_name), '') IS NOT NULL
ON CONFLICT (city_name, country_id) DO NOTHING;

INSERT INTO star.dim_supplier (
    supplier_name, contact_name, email, phone, address, city_id
)
SELECT DISTINCT ON (TRIM(m.supplier_email))
    NULLIF(TRIM(m.supplier_name), ''),
    NULLIF(TRIM(m.supplier_contact), ''),
    TRIM(m.supplier_email),
    NULLIF(TRIM(m.supplier_phone), ''),
    NULLIF(TRIM(m.supplier_address), ''),
    ci.city_id
FROM mock_data m
LEFT JOIN star.dim_country co
    ON co.country_name = TRIM(m.supplier_country)
LEFT JOIN star.dim_city ci
    ON ci.city_name = TRIM(m.supplier_city)
   AND ci.country_id = co.country_id
WHERE NULLIF(TRIM(m.supplier_email), '') IS NOT NULL
ORDER BY TRIM(m.supplier_email)
ON CONFLICT (email) DO NOTHING;

INSERT INTO star.dim_customer (
    first_name, last_name, age, email, postal_code,
    country_id, pet_type_id, pet_breed_id, pet_name
)
SELECT DISTINCT ON (TRIM(m.customer_email))
    NULLIF(TRIM(m.customer_first_name), ''),
    NULLIF(TRIM(m.customer_last_name), ''),
    NULLIF(TRIM(m.customer_age), '')::INTEGER,
    TRIM(m.customer_email),
    NULLIF(TRIM(m.customer_postal_code), ''),
    co.country_id,
    pt.pet_type_id,
    pb.pet_breed_id,
    NULLIF(TRIM(m.customer_pet_name), '')
FROM mock_data m
LEFT JOIN star.dim_country co
    ON co.country_name = TRIM(m.customer_country)
LEFT JOIN star.dim_pet_type pt
    ON pt.pet_type_name = TRIM(m.customer_pet_type)
LEFT JOIN star.dim_pet_breed pb
    ON pb.breed_name = TRIM(m.customer_pet_breed)
WHERE NULLIF(TRIM(m.customer_email), '') IS NOT NULL
ORDER BY TRIM(m.customer_email)
ON CONFLICT (email) DO NOTHING;

INSERT INTO star.dim_seller (
    first_name, last_name, email, postal_code, country_id
)
SELECT DISTINCT ON (TRIM(m.seller_email))
    NULLIF(TRIM(m.seller_first_name), ''),
    NULLIF(TRIM(m.seller_last_name), ''),
    TRIM(m.seller_email),
    NULLIF(TRIM(m.seller_postal_code), ''),
    co.country_id
FROM mock_data m
LEFT JOIN star.dim_country co
    ON co.country_name = TRIM(m.seller_country)
WHERE NULLIF(TRIM(m.seller_email), '') IS NOT NULL
ORDER BY TRIM(m.seller_email)
ON CONFLICT (email) DO NOTHING;

INSERT INTO star.dim_store (
    store_name, location, state_name, phone, email, city_id
)
SELECT DISTINCT ON (TRIM(m.store_email))
    NULLIF(TRIM(m.store_name), ''),
    NULLIF(TRIM(m.store_location), ''),
    NULLIF(TRIM(m.store_state), ''),
    NULLIF(TRIM(m.store_phone), ''),
    TRIM(m.store_email),
    ci.city_id
FROM mock_data m
LEFT JOIN star.dim_country co
    ON co.country_name = TRIM(m.store_country)
LEFT JOIN star.dim_city ci
    ON ci.city_name = TRIM(m.store_city)
   AND ci.country_id = co.country_id
WHERE NULLIF(TRIM(m.store_email), '') IS NOT NULL
ORDER BY TRIM(m.store_email)
ON CONFLICT (email) DO NOTHING;

-- product_nk = md5 атрибутов, т.к. sale_product_id повторяется между файлами
INSERT INTO star.dim_product (
    product_name, price, stock_quantity, weight, rating, reviews, description,
    release_date, expiry_date,
    category_id, pet_category_id, brand_id, color_id, size_id, material_id,
    supplier_id, product_nk
)
SELECT DISTINCT ON (nk.product_nk)
    NULLIF(TRIM(m.product_name), ''),
    NULLIF(TRIM(m.product_price), '')::NUMERIC(12, 2),
    NULLIF(TRIM(m.product_quantity), '')::INTEGER,
    NULLIF(TRIM(m.product_weight), '')::NUMERIC(12, 2),
    NULLIF(TRIM(m.product_rating), '')::NUMERIC(4, 2),
    NULLIF(TRIM(m.product_reviews), '')::INTEGER,
    NULLIF(TRIM(m.product_description), ''),
    CASE WHEN NULLIF(TRIM(m.product_release_date), '') IS NULL THEN NULL
         ELSE TO_DATE(m.product_release_date, 'MM/DD/YYYY') END,
    CASE WHEN NULLIF(TRIM(m.product_expiry_date), '') IS NULL THEN NULL
         ELSE TO_DATE(m.product_expiry_date, 'MM/DD/YYYY') END,
    pc.category_id,
    pcat.pet_category_id,
    b.brand_id,
    col.color_id,
    sz.size_id,
    mat.material_id,
    s.supplier_id,
    nk.product_nk
FROM mock_data m
CROSS JOIN LATERAL (
    SELECT md5(concat_ws('|',
        COALESCE(TRIM(m.product_name), ''),
        COALESCE(TRIM(m.product_category), ''),
        COALESCE(TRIM(m.product_price), ''),
        COALESCE(TRIM(m.product_quantity), ''),
        COALESCE(TRIM(m.pet_category), ''),
        COALESCE(TRIM(m.product_weight), ''),
        COALESCE(TRIM(m.product_color), ''),
        COALESCE(TRIM(m.product_size), ''),
        COALESCE(TRIM(m.product_brand), ''),
        COALESCE(TRIM(m.product_material), ''),
        COALESCE(TRIM(m.product_description), ''),
        COALESCE(TRIM(m.product_rating), ''),
        COALESCE(TRIM(m.product_reviews), ''),
        COALESCE(TRIM(m.product_release_date), ''),
        COALESCE(TRIM(m.product_expiry_date), ''),
        COALESCE(TRIM(m.supplier_email), '')
    )) AS product_nk
) nk
LEFT JOIN star.dim_product_category pc
    ON pc.category_name = TRIM(m.product_category)
LEFT JOIN star.dim_pet_category pcat
    ON pcat.pet_category_name = TRIM(m.pet_category)
LEFT JOIN star.dim_brand b
    ON b.brand_name = TRIM(m.product_brand)
LEFT JOIN star.dim_color col
    ON col.color_name = TRIM(m.product_color)
LEFT JOIN star.dim_size sz
    ON sz.size_name = TRIM(m.product_size)
LEFT JOIN star.dim_material mat
    ON mat.material_name = TRIM(m.product_material)
LEFT JOIN star.dim_supplier s
    ON s.email = TRIM(m.supplier_email)
ORDER BY nk.product_nk
ON CONFLICT (product_nk) DO NOTHING;

INSERT INTO star.fact_sales (
    sale_date_id, customer_id, seller_id, product_id, store_id,
    sale_quantity, sale_total_price
)
SELECT
    d.date_id,
    c.customer_id,
    s.seller_id,
    p.product_id,
    st.store_id,
    NULLIF(TRIM(m.sale_quantity), '')::INTEGER,
    NULLIF(TRIM(m.sale_total_price), '')::NUMERIC(14, 2)
FROM mock_data m
JOIN star.dim_date d
    ON d.full_date = TO_DATE(m.sale_date, 'MM/DD/YYYY')
JOIN star.dim_customer c
    ON c.email = TRIM(m.customer_email)
JOIN star.dim_seller s
    ON s.email = TRIM(m.seller_email)
JOIN star.dim_store st
    ON st.email = TRIM(m.store_email)
JOIN LATERAL (
    SELECT md5(concat_ws('|',
        COALESCE(TRIM(m.product_name), ''),
        COALESCE(TRIM(m.product_category), ''),
        COALESCE(TRIM(m.product_price), ''),
        COALESCE(TRIM(m.product_quantity), ''),
        COALESCE(TRIM(m.pet_category), ''),
        COALESCE(TRIM(m.product_weight), ''),
        COALESCE(TRIM(m.product_color), ''),
        COALESCE(TRIM(m.product_size), ''),
        COALESCE(TRIM(m.product_brand), ''),
        COALESCE(TRIM(m.product_material), ''),
        COALESCE(TRIM(m.product_description), ''),
        COALESCE(TRIM(m.product_rating), ''),
        COALESCE(TRIM(m.product_reviews), ''),
        COALESCE(TRIM(m.product_release_date), ''),
        COALESCE(TRIM(m.product_expiry_date), ''),
        COALESCE(TRIM(m.supplier_email), '')
    )) AS product_nk
) nk ON TRUE
JOIN star.dim_product p
    ON p.product_nk = nk.product_nk;
