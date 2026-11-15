CREATE OR REPLACE PACKAGE Dashboard_Package AS

    PROCEDURE GetDashboardStatistics;

    PROCEDURE GetLowStockProducts;

    PROCEDURE GetBestSellingBrands;

END Dashboard_Package;
/
CREATE OR REPLACE PACKAGE BODY Dashboard_Package AS

    -- 1. Get Dashboard Statistics
    PROCEDURE GetDashboardStatistics AS
    V_RESULT SYS_REFCURSOR;
BEGIN
    OPEN V_RESULT FOR
        SELECT
            (SELECT COUNT(*)
             FROM PRODUCTS P
             INNER JOIN BRANDS B
                 ON B.BRAND_ID = P.BRAND_ID
             INNER JOIN CATEGORIES C
                 ON C.CATEGORY_ID = P.CATEGORY_ID
             WHERE P.IS_DELETED = 'N'
               AND B.IS_DELETED = 'N'
               AND C.IS_DELETED = 'N') AS TOTAL_PRODUCTS,

            (SELECT COUNT(*)
             FROM PRODUCTS P
             INNER JOIN BRANDS B
                 ON B.BRAND_ID = P.BRAND_ID
             INNER JOIN CATEGORIES C
                 ON C.CATEGORY_ID = P.CATEGORY_ID
             WHERE P.IS_DELETED = 'N'
               AND P.STATUS = 'OUTOFSTOCK'
               AND B.IS_DELETED = 'N'
               AND C.IS_DELETED = 'N') AS OUT_OF_STOCK_PRODUCTS,

            (SELECT COUNT(*)
             FROM CATEGORIES
             WHERE IS_DELETED = 'N') AS TOTAL_CATEGORIES,

            (SELECT COUNT(*)
             FROM ORDERS) AS TOTAL_ORDERS,

            (SELECT COUNT(*)
             FROM ORDERS
             WHERE ORDER_STATUS = 'PENDING') AS PENDING_ORDERS,

            (SELECT COUNT(*)
             FROM ORDERS
             WHERE ORDER_STATUS = 'DELIVERED') AS DELIVERED_ORDERS,

            (SELECT COUNT(*)
             FROM ORDERS
             WHERE ORDER_STATUS = 'CANCELLED') AS CANCELLED_ORDERS,

            (SELECT NVL(SUM(TOTAL_AMOUNT), 0)
             FROM ORDERS
             WHERE ORDER_STATUS = 'DELIVERED') AS TOTAL_SALES

        FROM DUAL;

    DBMS_SQL.RETURN_RESULT(V_RESULT);
END GetDashboardStatistics;


    -- 2. Get Low Stock Products
    PROCEDURE GetLowStockProducts AS
        V_RESULT SYS_REFCURSOR;
    BEGIN
        OPEN V_RESULT FOR
            SELECT
                P.PRODUCT_ID,
                P.NAME,
                P.STOCK,
                P.PRICE,
                P.STATUS,
                P.PRODUCT_IMG_URL
            FROM PRODUCTS P
            INNER JOIN BRANDS B
                ON B.BRAND_ID = P.BRAND_ID
            INNER JOIN CATEGORIES C
                ON C.CATEGORY_ID = P.CATEGORY_ID
            WHERE P.STOCK <= 5
              AND P.IS_DELETED = 'N'
              AND B.IS_DELETED = 'N'
              AND C.IS_DELETED = 'N'
            ORDER BY P.STOCK ASC;

        DBMS_SQL.RETURN_RESULT(V_RESULT);
    END GetLowStockProducts;


    -- 3. Get Best Selling Brands
    PROCEDURE GetBestSellingBrands AS
    V_RESULT SYS_REFCURSOR;
BEGIN
    OPEN V_RESULT FOR
        SELECT
            B.BRAND_ID,
            B.NAME AS BRAND_NAME,
            SUM(OI.QUANTITY) AS TOTAL_SOLD
        FROM BRANDS B
        JOIN PRODUCTS P
            ON P.BRAND_ID = B.BRAND_ID
        JOIN ORDER_ITEMS OI
            ON OI.PRODUCT_ID = P.PRODUCT_ID
        JOIN ORDERS O
            ON O.ORDER_ID = OI.ORDER_ID
        WHERE O.ORDER_STATUS = 'DELIVERED'
          AND B.IS_DELETED = 'N'
        GROUP BY B.BRAND_ID, B.NAME
        ORDER BY TOTAL_SOLD DESC, B.BRAND_ID
        FETCH FIRST 5 ROWS ONLY;

    DBMS_SQL.RETURN_RESULT(V_RESULT);
END GetBestSellingBrands;

END Dashboard_Package;
/