CREATE OR REPLACE PACKAGE Brands_Package AS

    PROCEDURE GetAllBrands;

    PROCEDURE CreateBrand(
        P_BRAND_NAME IN BRANDS.NAME%TYPE,
        P_BRAND_ID OUT BRANDS.BRAND_ID%TYPE
    );

    PROCEDURE UpdateBrand(
        P_BRAND_ID IN BRANDS.BRAND_ID%TYPE,
        P_BRAND_NAME IN BRANDS.NAME%TYPE
    );

    PROCEDURE DeleteBrand(
        P_BRAND_ID IN BRANDS.BRAND_ID%TYPE
    );

    PROCEDURE GetBrandById(
        P_BRAND_ID IN BRANDS.BRAND_ID%TYPE
    );

END Brands_Package;
/

CREATE OR REPLACE PACKAGE BODY Brands_Package AS

    PROCEDURE GetAllBrands AS
        V_CURSOR SYS_REFCURSOR;
    BEGIN
        OPEN V_CURSOR FOR
            SELECT BRAND_ID, NAME
            FROM BRANDS
            WHERE IS_DELETED = 'N'
            ORDER BY BRAND_ID;

        DBMS_SQL.RETURN_RESULT(V_CURSOR);
    END GetAllBrands;


    PROCEDURE CreateBrand(
        P_BRAND_NAME IN BRANDS.NAME%TYPE,
        P_BRAND_ID OUT BRANDS.BRAND_ID%TYPE
    ) AS
    BEGIN
        INSERT INTO BRANDS (NAME)
        VALUES (TRIM(P_BRAND_NAME))
        RETURNING BRAND_ID INTO P_BRAND_ID;

        COMMIT;

    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(
                -20012,
                'Brand name already exists.'
            );

        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END CreateBrand;


    PROCEDURE UpdateBrand(
        P_BRAND_ID IN BRANDS.BRAND_ID%TYPE,
        P_BRAND_NAME IN BRANDS.NAME%TYPE
    ) AS
    BEGIN
        UPDATE BRANDS
        SET NAME = TRIM(P_BRAND_NAME)
        WHERE BRAND_ID = P_BRAND_ID
          AND IS_DELETED = 'N';

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20011,
                'Brand not found.'
            );
        END IF;

        COMMIT;

    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(
                -20012,
                'Brand name already exists.'
            );

        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END UpdateBrand;


    PROCEDURE DeleteBrand(
        P_BRAND_ID IN BRANDS.BRAND_ID%TYPE
    ) AS
        V_BRAND_ID BRANDS.BRAND_ID%TYPE;
        V_HAS_PRODUCTS NUMBER;
    BEGIN
        BEGIN
            SELECT BRAND_ID
            INTO V_BRAND_ID
            FROM BRANDS
            WHERE BRAND_ID = P_BRAND_ID
              AND IS_DELETED = 'N';

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(
                    -20011,
                    'Brand not found.'
                );
        END;

        SELECT COUNT(*)
        INTO V_HAS_PRODUCTS
        FROM PRODUCTS
        WHERE BRAND_ID = P_BRAND_ID
          AND IS_DELETED = 'N';

        IF V_HAS_PRODUCTS > 0 THEN
            RAISE_APPLICATION_ERROR(
                -20013,
                'Cannot delete brand because it has active products.'
            );
        END IF;

        UPDATE BRANDS
        SET IS_DELETED = 'Y'
        WHERE BRAND_ID = P_BRAND_ID
          AND IS_DELETED = 'N';

        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END DeleteBrand;


    PROCEDURE GetBrandById(
        P_BRAND_ID IN BRANDS.BRAND_ID%TYPE
    ) AS
        V_CURSOR SYS_REFCURSOR;
        V_BRAND_ID BRANDS.BRAND_ID%TYPE;
    BEGIN
        SELECT BRAND_ID
        INTO V_BRAND_ID
        FROM BRANDS
        WHERE BRAND_ID = P_BRAND_ID
          AND IS_DELETED = 'N';

        OPEN V_CURSOR FOR
            SELECT BRAND_ID, NAME
            FROM BRANDS
            WHERE BRAND_ID = P_BRAND_ID
              AND IS_DELETED = 'N';

        DBMS_SQL.RETURN_RESULT(V_CURSOR);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20011,
                'Brand not found.'
            );
    END GetBrandById;

END Brands_Package;
/
