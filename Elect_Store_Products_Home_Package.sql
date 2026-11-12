CREATE OR REPLACE PACKAGE Products_Home_Package AS

    PROCEDURE GetFeaturedProducts;
    PROCEDURE GetNewArrivals;
    PROCEDURE GetBestSellingProducts;

END Products_Home_Package;
/

CREATE OR REPLACE PACKAGE BODY Products_Home_Package AS

    -- 1. Featured Products
    PROCEDURE GetFeaturedProducts AS
        P_CURSOR SYS_REFCURSOR;
    BEGIN
        OPEN P_CURSOR FOR
            SELECT
                P.PRODUCT_ID AS ProductId,
                P.NAME AS Name,
                P.PRICE AS Price,
                P.PRODUCT_IMG_URL AS ProductImgUrl,
                B.NAME AS BrandName,
                C.NAME AS CategoryName
            FROM PRODUCTS P
            INNER JOIN BRANDS B
                ON P.BRAND_ID = B.BRAND_ID
            INNER JOIN CATEGORIES C
                ON P.CATEGORY_ID = C.CATEGORY_ID
            WHERE P.IS_FEATURED = 'Y'
              AND P.IS_DELETED = 'N'
              AND P.STATUS = 'AVAILABLE'
              AND B.IS_DELETED = 'N'
              AND C.IS_DELETED = 'N'
            ORDER BY P.CREATED_AT DESC, P.PRODUCT_ID DESC;

        DBMS_SQL.RETURN_RESULT(P_CURSOR);
    END GetFeaturedProducts;


    -- 2. New Arrivals
    PROCEDURE GetNewArrivals AS
        P_CURSOR SYS_REFCURSOR;
    BEGIN
        OPEN P_CURSOR FOR
            SELECT
                P.PRODUCT_ID AS ProductId,
                P.NAME AS Name,
                P.PRICE AS Price,
                P.PRODUCT_IMG_URL AS ProductImgUrl,
                B.NAME AS BrandName,
                C.NAME AS CategoryName
            FROM PRODUCTS P
            INNER JOIN BRANDS B
                ON P.BRAND_ID = B.BRAND_ID
            INNER JOIN CATEGORIES C
                ON P.CATEGORY_ID = C.CATEGORY_ID
            WHERE P.IS_DELETED = 'N'
              AND P.STATUS = 'AVAILABLE'
              AND B.IS_DELETED = 'N'
              AND C.IS_DELETED = 'N'
            ORDER BY P.CREATED_AT DESC, P.PRODUCT_ID DESC
            FETCH FIRST 10 ROWS ONLY;

        DBMS_SQL.RETURN_RESULT(P_CURSOR);
    END GetNewArrivals;


    -- 3. Best-Selling Products
    PROCEDURE GetBestSellingProducts AS
        P_CURSOR SYS_REFCURSOR;
    BEGIN
        OPEN P_CURSOR FOR
            SELECT
                P.PRODUCT_ID AS ProductId,
                P.NAME AS Name,
                P.PRICE AS Price,
                P.PRODUCT_IMG_URL AS ProductImgUrl,
                B.NAME AS BrandName,
                C.NAME AS CategoryName
            FROM PRODUCTS P
            INNER JOIN BRANDS B
                ON P.BRAND_ID = B.BRAND_ID
            INNER JOIN CATEGORIES C
                ON P.CATEGORY_ID = C.CATEGORY_ID
            INNER JOIN (
                SELECT
                    OI.PRODUCT_ID,
                    SUM(OI.QUANTITY) AS TOTAL_SOLD
                FROM ORDER_ITEMS OI
                INNER JOIN ORDERS O
                    ON O.ORDER_ID = OI.ORDER_ID
                WHERE O.ORDER_STATUS = 'DELIVERED'
                GROUP BY OI.PRODUCT_ID
                ORDER BY TOTAL_SOLD DESC
                FETCH FIRST 10 ROWS ONLY
            ) S
                ON S.PRODUCT_ID = P.PRODUCT_ID
            WHERE P.IS_DELETED = 'N'
              AND P.STATUS = 'AVAILABLE'
              AND B.IS_DELETED = 'N'
              AND C.IS_DELETED = 'N'
            ORDER BY S.TOTAL_SOLD DESC;

        DBMS_SQL.RETURN_RESULT(P_CURSOR);
    END GetBestSellingProducts;

END Products_Home_Package;
/






