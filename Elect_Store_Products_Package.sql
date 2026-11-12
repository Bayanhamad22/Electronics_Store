CREATE OR REPLACE PACKAGE Products_Package AS

    PROCEDURE GetAllProducts(
        P_CATEGORY_ID IN NUMBER DEFAULT NULL,
        P_BRAND_ID    IN NUMBER DEFAULT NULL,
        P_MIN_PRICE   IN NUMBER DEFAULT NULL,
        P_MAX_PRICE   IN NUMBER DEFAULT NULL,
        P_STATUS      IN VARCHAR2 DEFAULT NULL,
        P_SEARCH      IN VARCHAR2 DEFAULT NULL,
        P_SORT_BY     IN VARCHAR2 DEFAULT 'NAME',
        P_SORT_ORDER  IN VARCHAR2 DEFAULT 'ASC'
    );

    PROCEDURE GetProductDetails(
        P_PRODUCT_ID IN PRODUCTS.PRODUCT_ID%TYPE
    );

    PROCEDURE GetProductSpecifications(
        P_PRODUCT_ID IN PRODUCTS.PRODUCT_ID%TYPE
    );
    
    PROCEDURE CreateProduct(
    P_NAME                 IN PRODUCTS.NAME%TYPE,
    P_DESCRIPTION          IN PRODUCTS.DESCRIPTION%TYPE,
    P_PRICE                IN PRODUCTS.PRICE%TYPE,
    P_WARRANTY_INFORMATION IN PRODUCTS.WARRANTY_INFORMATION%TYPE,
    P_PRODUCT_IMG_URL      IN PRODUCTS.PRODUCT_IMG_URL%TYPE,
    P_STOCK                IN PRODUCTS.STOCK%TYPE,
    P_IS_FEATURED          IN PRODUCTS.IS_FEATURED%TYPE,
    P_BRAND_ID             IN PRODUCTS.BRAND_ID%TYPE,
    P_CATEGORY_ID          IN PRODUCTS.CATEGORY_ID%TYPE,
    P_SPECIFICATIONS_JSON  IN CLOB,
    P_PRODUCT_ID           OUT PRODUCTS.PRODUCT_ID%TYPE
);

    PROCEDURE UpdateProduct(
    P_PRODUCT_ID           IN PRODUCTS.PRODUCT_ID%TYPE,
    P_NAME                 IN PRODUCTS.NAME%TYPE,
    P_DESCRIPTION          IN PRODUCTS.DESCRIPTION%TYPE,
    P_PRICE                IN PRODUCTS.PRICE%TYPE,
    P_WARRANTY_INFORMATION IN PRODUCTS.WARRANTY_INFORMATION%TYPE,
    P_PRODUCT_IMG_URL      IN PRODUCTS.PRODUCT_IMG_URL%TYPE,
    P_STOCK                IN PRODUCTS.STOCK%TYPE,
    P_IS_FEATURED          IN PRODUCTS.IS_FEATURED%TYPE,
    P_BRAND_ID             IN PRODUCTS.BRAND_ID%TYPE,
    P_CATEGORY_ID          IN PRODUCTS.CATEGORY_ID%TYPE,
    P_SPECIFICATIONS_JSON  IN CLOB
);

PROCEDURE DeleteProduct(
    P_PRODUCT_ID IN PRODUCTS.PRODUCT_ID%TYPE
);

END Products_Package;
/

CREATE OR REPLACE PACKAGE BODY Products_Package AS

    PROCEDURE GetAllProducts(
        P_CATEGORY_ID IN NUMBER,
        P_BRAND_ID    IN NUMBER,
        P_MIN_PRICE   IN NUMBER,
        P_MAX_PRICE   IN NUMBER,
        P_STATUS      IN VARCHAR2,
        P_SEARCH      IN VARCHAR2,
        P_SORT_BY     IN VARCHAR2,
        P_SORT_ORDER  IN VARCHAR2
    )
    AS
        C_FILTER SYS_REFCURSOR;
    BEGIN
        OPEN C_FILTER FOR
            SELECT
                P.PRODUCT_ID AS ProductId,
                P.NAME AS Name,
                P.PRODUCT_IMG_URL AS ProductImgUrl,
                P.PRICE AS Price,
                B.NAME AS BrandName,
                C.NAME AS CategoryName,
                P.DESCRIPTION AS Description,
                P.WARRANTY_INFORMATION AS WarrantyInformation,
                P.STATUS AS Status,
                P.STOCK AS Stock
            FROM PRODUCTS P
            INNER JOIN BRANDS B
                ON B.BRAND_ID = P.BRAND_ID
            INNER JOIN CATEGORIES C
                ON C.CATEGORY_ID = P.CATEGORY_ID
            WHERE P.IS_DELETED = 'N'
              AND B.IS_DELETED = 'N'
              AND C.IS_DELETED = 'N'
              AND (P_CATEGORY_ID IS NULL
                   OR P.CATEGORY_ID = P_CATEGORY_ID)
              AND (P_BRAND_ID IS NULL
                   OR P.BRAND_ID = P_BRAND_ID)
              AND (P_MIN_PRICE IS NULL
                   OR P.PRICE >= P_MIN_PRICE)
              AND (P_MAX_PRICE IS NULL
                   OR P.PRICE <= P_MAX_PRICE)
              AND (P_STATUS IS NULL
                   OR UPPER(P.STATUS) = UPPER(P_STATUS))
              AND (P_SEARCH IS NULL
                   OR UPPER(P.NAME) LIKE
                      '%' || UPPER(TRIM(P_SEARCH)) || '%')
            ORDER BY
                CASE
                    WHEN UPPER(P_SORT_BY) = 'NAME'
                     AND UPPER(P_SORT_ORDER) = 'ASC'
                    THEN P.NAME
                END ASC,
                CASE
                    WHEN UPPER(P_SORT_BY) = 'NAME'
                     AND UPPER(P_SORT_ORDER) = 'DESC'
                    THEN P.NAME
                END DESC,
                CASE
                    WHEN UPPER(P_SORT_BY) = 'PRICE'
                     AND UPPER(P_SORT_ORDER) = 'ASC'
                    THEN P.PRICE
                END ASC,
                CASE
                    WHEN UPPER(P_SORT_BY) = 'PRICE'
                     AND UPPER(P_SORT_ORDER) = 'DESC'
                    THEN P.PRICE
                END DESC,
                P.PRODUCT_ID ASC;

        DBMS_SQL.RETURN_RESULT(C_FILTER);
    END GetAllProducts;


    PROCEDURE GetProductDetails(
        P_PRODUCT_ID IN PRODUCTS.PRODUCT_ID%TYPE
    )
    AS
        C_DETAILS SYS_REFCURSOR;
    BEGIN
        OPEN C_DETAILS FOR
            SELECT
                P.PRODUCT_ID AS ProductId,
                P.NAME AS Name,
                P.DESCRIPTION AS Description,
                P.PRICE AS Price,
                P.PRODUCT_IMG_URL AS ProductImgUrl,
                P.WARRANTY_INFORMATION AS WarrantyInformation,
                B.NAME AS BrandName,
                C.NAME AS CategoryName,
                P.STATUS AS Status,
                P.STOCK AS Stock
            FROM PRODUCTS P
            INNER JOIN BRANDS B
                ON B.BRAND_ID = P.BRAND_ID
            INNER JOIN CATEGORIES C
                ON C.CATEGORY_ID = P.CATEGORY_ID
            WHERE P.PRODUCT_ID = P_PRODUCT_ID
                AND P.IS_DELETED = 'N'
                AND B.IS_DELETED = 'N'
                AND C.IS_DELETED = 'N';

        DBMS_SQL.RETURN_RESULT(C_DETAILS);
    END GetProductDetails;


    PROCEDURE GetProductSpecifications(
        P_PRODUCT_ID IN PRODUCTS.PRODUCT_ID%TYPE
    )
    AS
        C_SPECIFICATIONS SYS_REFCURSOR;
    BEGIN
        OPEN C_SPECIFICATIONS FOR
            SELECT
                PS.PRODUCT_SPEC_ID AS ProductSpecId,
                PS.NAME AS Name,
                PS.VALUE AS Value
            FROM PRODUCT_SPECIFICATIONS PS
            WHERE PS.PRODUCT_ID = P_PRODUCT_ID
                AND EXISTS (
    SELECT 1
    FROM PRODUCTS P
    INNER JOIN BRANDS B
        ON B.BRAND_ID = P.BRAND_ID
    INNER JOIN CATEGORIES C
        ON C.CATEGORY_ID = P.CATEGORY_ID
    WHERE P.PRODUCT_ID = PS.PRODUCT_ID
      AND P.IS_DELETED = 'N'
      AND B.IS_DELETED = 'N'
      AND C.IS_DELETED = 'N'
)
            ORDER BY PS.PRODUCT_SPEC_ID;

        DBMS_SQL.RETURN_RESULT(C_SPECIFICATIONS);
    END GetProductSpecifications;


    
PROCEDURE CreateProduct(
    P_NAME                 IN PRODUCTS.NAME%TYPE,
    P_DESCRIPTION          IN PRODUCTS.DESCRIPTION%TYPE,
    P_PRICE                IN PRODUCTS.PRICE%TYPE,
    P_WARRANTY_INFORMATION IN PRODUCTS.WARRANTY_INFORMATION%TYPE,
    P_PRODUCT_IMG_URL      IN PRODUCTS.PRODUCT_IMG_URL%TYPE,
    P_STOCK                IN PRODUCTS.STOCK%TYPE,
    P_IS_FEATURED          IN PRODUCTS.IS_FEATURED%TYPE,
    P_BRAND_ID             IN PRODUCTS.BRAND_ID%TYPE,
    P_CATEGORY_ID          IN PRODUCTS.CATEGORY_ID%TYPE,
    P_SPECIFICATIONS_JSON  IN CLOB,
    P_PRODUCT_ID           OUT PRODUCTS.PRODUCT_ID%TYPE
)
AS
    V_BRAND_ID BRANDS.BRAND_ID%TYPE;
    V_CATEGORY_ID CATEGORIES.CATEGORY_ID%TYPE;
BEGIN
    SAVEPOINT SP_CREATE_PRODUCT;

    -- Validate Brand
    BEGIN
        SELECT BRAND_ID
        INTO V_BRAND_ID
        FROM BRANDS
        WHERE BRAND_ID = P_BRAND_ID
          AND IS_DELETED = 'N';

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20014,
                'Brand not found or deleted.'
            );
    END;


    -- Validate Category
    BEGIN
        SELECT CATEGORY_ID
        INTO V_CATEGORY_ID
        FROM CATEGORIES
        WHERE CATEGORY_ID = P_CATEGORY_ID
          AND IS_DELETED = 'N';

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20024,
                'Category not found or deleted.'
            );
    END;


    INSERT INTO PRODUCTS (
        NAME,
        DESCRIPTION,
        PRICE,
        WARRANTY_INFORMATION,
        PRODUCT_IMG_URL,
        STOCK,
        IS_FEATURED,
        STATUS,
        BRAND_ID,
        CATEGORY_ID
    )
    VALUES (
        P_NAME,
        P_DESCRIPTION,
        P_PRICE,
        P_WARRANTY_INFORMATION,
        P_PRODUCT_IMG_URL,
        P_STOCK,
        P_IS_FEATURED,
        CASE
            WHEN P_STOCK > 0 THEN 'AVAILABLE'
            ELSE 'OUTOFSTOCK'
        END,
        P_BRAND_ID,
        P_CATEGORY_ID
    )
    RETURNING PRODUCT_ID INTO P_PRODUCT_ID;


    IF P_SPECIFICATIONS_JSON IS NOT NULL THEN
        INSERT INTO PRODUCT_SPECIFICATIONS (
            NAME,
            VALUE,
            PRODUCT_ID
        )
        SELECT
            S.NAME,
            S.VALUE,
            P_PRODUCT_ID
        FROM JSON_TABLE(
            P_SPECIFICATIONS_JSON,
            '$[*]'
            COLUMNS (
                NAME  VARCHAR2(255) PATH '$.name',
                VALUE VARCHAR2(255) PATH '$.value'
            )
        ) S;
    END IF;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO SP_CREATE_PRODUCT;
        RAISE;
END CreateProduct;



PROCEDURE UpdateProduct(
    P_PRODUCT_ID           IN PRODUCTS.PRODUCT_ID%TYPE,
    P_NAME                 IN PRODUCTS.NAME%TYPE,
    P_DESCRIPTION          IN PRODUCTS.DESCRIPTION%TYPE,
    P_PRICE                IN PRODUCTS.PRICE%TYPE,
    P_WARRANTY_INFORMATION IN PRODUCTS.WARRANTY_INFORMATION%TYPE,
    P_PRODUCT_IMG_URL      IN PRODUCTS.PRODUCT_IMG_URL%TYPE,
    P_STOCK                IN PRODUCTS.STOCK%TYPE,
    P_IS_FEATURED          IN PRODUCTS.IS_FEATURED%TYPE,
    P_BRAND_ID             IN PRODUCTS.BRAND_ID%TYPE,
    P_CATEGORY_ID          IN PRODUCTS.CATEGORY_ID%TYPE,
    P_SPECIFICATIONS_JSON  IN CLOB
)
AS
    V_BRAND_ID BRANDS.BRAND_ID%TYPE;
    V_CATEGORY_ID CATEGORIES.CATEGORY_ID%TYPE;
BEGIN
    SAVEPOINT SP_UPDATE_PRODUCT;

    -- Validate Brand
    BEGIN
        SELECT BRAND_ID
        INTO V_BRAND_ID
        FROM BRANDS
        WHERE BRAND_ID = P_BRAND_ID
          AND IS_DELETED = 'N';

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20014,
                'Brand not found or deleted.'
            );
    END;


    -- Validate Category
    BEGIN
        SELECT CATEGORY_ID
        INTO V_CATEGORY_ID
        FROM CATEGORIES
        WHERE CATEGORY_ID = P_CATEGORY_ID
          AND IS_DELETED = 'N';

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20024,
                'Category not found or deleted.'
            );
    END;


    UPDATE PRODUCTS
    SET
        NAME = P_NAME,
        DESCRIPTION = P_DESCRIPTION,
        PRICE = P_PRICE,
        WARRANTY_INFORMATION = P_WARRANTY_INFORMATION,
        PRODUCT_IMG_URL = P_PRODUCT_IMG_URL,
        STATUS = CASE
            WHEN P_STOCK > 0 THEN 'AVAILABLE'
            ELSE 'OUTOFSTOCK'
        END,
        STOCK = P_STOCK,
        IS_FEATURED = P_IS_FEATURED,
        BRAND_ID = P_BRAND_ID,
        CATEGORY_ID = P_CATEGORY_ID,
        UPDATED_AT = SYSDATE
    WHERE PRODUCT_ID = P_PRODUCT_ID
      AND IS_DELETED = 'N';

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Product not found.'
        );
    END IF;


    DELETE FROM PRODUCT_SPECIFICATIONS
    WHERE PRODUCT_ID = P_PRODUCT_ID;


    IF P_SPECIFICATIONS_JSON IS NOT NULL THEN
        INSERT INTO PRODUCT_SPECIFICATIONS (
            NAME,
            VALUE,
            PRODUCT_ID
        )
        SELECT
            S.NAME,
            S.VALUE,
            P_PRODUCT_ID
        FROM JSON_TABLE(
            P_SPECIFICATIONS_JSON,
            '$[*]'
            COLUMNS (
                NAME  VARCHAR2(255) PATH '$.name',
                VALUE VARCHAR2(255) PATH '$.value'
            )
        ) S;
    END IF;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO SP_UPDATE_PRODUCT;
        RAISE;
END UpdateProduct;



PROCEDURE DeleteProduct(
    P_PRODUCT_ID IN PRODUCTS.PRODUCT_ID%TYPE
)
AS
BEGIN
    UPDATE PRODUCTS
    SET
        IS_DELETED = 'Y',
        UPDATED_AT = SYSDATE
    WHERE PRODUCT_ID = P_PRODUCT_ID
      AND IS_DELETED = 'N';

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Product not found.');
    END IF;

    COMMIT;
END DeleteProduct; 
     
END Products_Package;
/

