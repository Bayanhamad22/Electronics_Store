CREATE OR REPLACE PACKAGE Categories_Package AS

    PROCEDURE GetAllCategories;

    PROCEDURE CreateCategory(
        P_CATEGORY_NAME IN CATEGORIES.NAME%TYPE,
        P_CATEGORY_ID OUT CATEGORIES.CATEGORY_ID%TYPE
    );

    PROCEDURE UpdateCategory(
        P_CATEGORY_ID IN CATEGORIES.CATEGORY_ID%TYPE,
        P_CATEGORY_NAME IN CATEGORIES.NAME%TYPE
    );

    PROCEDURE DeleteCategory(
        P_CATEGORY_ID IN CATEGORIES.CATEGORY_ID%TYPE
    );

    PROCEDURE GetCategoryById(
        P_CATEGORY_ID IN CATEGORIES.CATEGORY_ID%TYPE
    );

END Categories_Package;
/

CREATE OR REPLACE PACKAGE BODY Categories_Package AS

    PROCEDURE GetAllCategories AS
        V_CURSOR SYS_REFCURSOR;
    BEGIN
        OPEN V_CURSOR FOR
            SELECT CATEGORY_ID, NAME
            FROM CATEGORIES
            WHERE IS_DELETED = 'N'
            ORDER BY CATEGORY_ID;

        DBMS_SQL.RETURN_RESULT(V_CURSOR);
    END GetAllCategories;


    PROCEDURE CreateCategory(
    P_CATEGORY_NAME IN CATEGORIES.NAME%TYPE,
    P_CATEGORY_ID OUT CATEGORIES.CATEGORY_ID%TYPE
) AS
BEGIN
    INSERT INTO CATEGORIES (NAME)
    VALUES (TRIM(P_CATEGORY_NAME))
    RETURNING CATEGORY_ID INTO P_CATEGORY_ID;

    COMMIT;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(
            -20022,
            'Category name already exists.'
        );

    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END CreateCategory;


    PROCEDURE UpdateCategory(
        P_CATEGORY_ID IN CATEGORIES.CATEGORY_ID%TYPE,
        P_CATEGORY_NAME IN CATEGORIES.NAME%TYPE
    ) AS
    BEGIN
        UPDATE CATEGORIES
        SET NAME = TRIM(P_CATEGORY_NAME)
        WHERE CATEGORY_ID = P_CATEGORY_ID
          AND IS_DELETED = 'N';

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20021,
                'Category not found.'
            );
        END IF;

        COMMIT;

    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(
                -20022,
                'Category name already exists.'
            );

        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END UpdateCategory;


    PROCEDURE DeleteCategory(
        P_CATEGORY_ID IN CATEGORIES.CATEGORY_ID%TYPE
    ) AS
        V_CATEGORY_ID CATEGORIES.CATEGORY_ID%TYPE;
        V_HAS_PRODUCTS NUMBER;
    BEGIN
        BEGIN
            SELECT CATEGORY_ID
            INTO V_CATEGORY_ID
            FROM CATEGORIES
            WHERE CATEGORY_ID = P_CATEGORY_ID
              AND IS_DELETED = 'N';

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(
                    -20021,
                    'Category not found.'
                );
        END;

        SELECT COUNT(*)
        INTO V_HAS_PRODUCTS
        FROM PRODUCTS
        WHERE CATEGORY_ID = P_CATEGORY_ID
          AND IS_DELETED = 'N';

        IF V_HAS_PRODUCTS > 0 THEN
            RAISE_APPLICATION_ERROR(
                -20023,
                'Cannot delete category because it has active products.'
            );
        END IF;

        UPDATE CATEGORIES
        SET IS_DELETED = 'Y'
        WHERE CATEGORY_ID = P_CATEGORY_ID
          AND IS_DELETED = 'N';

        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END DeleteCategory;


    PROCEDURE GetCategoryById(
        P_CATEGORY_ID IN CATEGORIES.CATEGORY_ID%TYPE
    ) AS
        V_CURSOR SYS_REFCURSOR;
        V_CATEGORY_ID CATEGORIES.CATEGORY_ID%TYPE;
    BEGIN
        SELECT CATEGORY_ID
        INTO V_CATEGORY_ID
        FROM CATEGORIES
        WHERE CATEGORY_ID = P_CATEGORY_ID
          AND IS_DELETED = 'N';

        OPEN V_CURSOR FOR
            SELECT CATEGORY_ID, NAME
            FROM CATEGORIES
            WHERE CATEGORY_ID = P_CATEGORY_ID
              AND IS_DELETED = 'N';

        DBMS_SQL.RETURN_RESULT(V_CURSOR);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20021,
                'Category not found.'
            );
    END GetCategoryById;

END Categories_Package;
/


