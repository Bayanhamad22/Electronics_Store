CREATE OR REPLACE PACKAGE Orders_Package AS

    PROCEDURE CreateOrder(
        P_USER_ID               IN ORDERS.USER_ID%TYPE,
        P_CUSTOMER_FULL_NAME    IN ORDERS.CUSTOMER_FULL_NAME%TYPE,
        P_CUSTOMER_PHONE_NUMBER IN ORDERS.CUSTOMER_PHONE_NUMBER%TYPE,
        P_SHIPPING_ADDRESS      IN ORDERS.SHIPPING_ADDRESS%TYPE,
        P_ITEMS_JSON            IN CLOB,
        P_ORDER_ID              OUT ORDERS.ORDER_ID%TYPE
    );

    PROCEDURE GetOrderById(
        P_ORDER_ID IN ORDERS.ORDER_ID%TYPE
    );

    PROCEDURE GetOrderItems(
        P_ORDER_ID IN ORDERS.ORDER_ID%TYPE
    );
    
    PROCEDURE GetAllOrders;
    
    PROCEDURE UpdateOrderStatus(
    P_ORDER_ID IN ORDERS.ORDER_ID%TYPE,
    P_ORDER_STATUS IN ORDERS.ORDER_STATUS%TYPE
    );

END Orders_Package;
/

CREATE OR REPLACE PACKAGE BODY Orders_Package AS

    -- 1. Create Order
    PROCEDURE CreateOrder(
        P_USER_ID               IN ORDERS.USER_ID%TYPE,
        P_CUSTOMER_FULL_NAME    IN ORDERS.CUSTOMER_FULL_NAME%TYPE,
        P_CUSTOMER_PHONE_NUMBER IN ORDERS.CUSTOMER_PHONE_NUMBER%TYPE,
        P_SHIPPING_ADDRESS      IN ORDERS.SHIPPING_ADDRESS%TYPE,
        P_ITEMS_JSON            IN CLOB,
        P_ORDER_ID              OUT ORDERS.ORDER_ID%TYPE
    )
    AS
        V_TOTAL_AMOUNT NUMBER(10,2) := 0;

        V_PRICE PRODUCTS.PRICE%TYPE;
        V_STOCK PRODUCTS.STOCK%TYPE;
        V_STATUS PRODUCTS.STATUS%TYPE;
        V_IS_DELETED PRODUCTS.IS_DELETED%TYPE;
        V_ACCOUNT_STATUS USERS.ACCOUNT_STATUS%TYPE;

    BEGIN

        SAVEPOINT SP_CREATE_ORDER;

        -- Check if user exists and is not deleted
        BEGIN
            SELECT ACCOUNT_STATUS
            INTO V_ACCOUNT_STATUS
            FROM USERS
            WHERE USER_ID = P_USER_ID
              AND IS_DELETED = 'N';

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(
                    -20005,
                    'User does not exist.'
                );
        END;

        -- Check if user account is active
        IF V_ACCOUNT_STATUS <> 'ACTIVE' THEN
            RAISE_APPLICATION_ERROR(
                -20006,
                'User account is not active.'
            );
        END IF;

        -- Check products availability and calculate total
        FOR ITEM IN (
            SELECT PRODUCT_ID, QUANTITY
            FROM JSON_TABLE(
                P_ITEMS_JSON,
                '$[*]'
                COLUMNS (
                    PRODUCT_ID NUMBER PATH '$.productId',
                    QUANTITY NUMBER PATH '$.quantity'
                )
            )
            ORDER BY PRODUCT_ID
        )
        LOOP

            BEGIN
                SELECT
                    PRICE,
                    STOCK,
                    STATUS,
                    IS_DELETED
                INTO
                    V_PRICE,
                    V_STOCK,
                    V_STATUS,
                    V_IS_DELETED
                FROM PRODUCTS
                WHERE PRODUCT_ID = ITEM.PRODUCT_ID
                FOR UPDATE;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(
                        -20002,
                        'Product does not exist.'
                    );
            END;

            IF V_IS_DELETED = 'Y' OR V_STATUS <> 'AVAILABLE' THEN
                RAISE_APPLICATION_ERROR(
                    -20003,
                    'Product is not available.'
                );
            END IF;

            IF V_STOCK < ITEM.QUANTITY THEN
                RAISE_APPLICATION_ERROR(
                    -20004,
                    'Insufficient product stock.'
                );
            END IF;

            V_TOTAL_AMOUNT :=
                V_TOTAL_AMOUNT + (V_PRICE * ITEM.QUANTITY);

        END LOOP;

        -- Create order
        INSERT INTO ORDERS (
            TOTAL_AMOUNT,
            SHIPPING_ADDRESS,
            CUSTOMER_PHONE_NUMBER,
            CUSTOMER_FULL_NAME,
            USER_ID
        )
        VALUES (
            V_TOTAL_AMOUNT,
            P_SHIPPING_ADDRESS,
            P_CUSTOMER_PHONE_NUMBER,
            P_CUSTOMER_FULL_NAME,
            P_USER_ID
        )
        RETURNING ORDER_ID INTO P_ORDER_ID;

        -- Insert order items and update stock
        FOR ITEM IN (
            SELECT PRODUCT_ID, QUANTITY
            FROM JSON_TABLE(
                P_ITEMS_JSON,
                '$[*]'
                COLUMNS (
                    PRODUCT_ID NUMBER PATH '$.productId',
                    QUANTITY NUMBER PATH '$.quantity'
                )
            )
        )
        LOOP

            SELECT PRICE
            INTO V_PRICE
            FROM PRODUCTS
            WHERE PRODUCT_ID = ITEM.PRODUCT_ID;

            INSERT INTO ORDER_ITEMS (
                UNIT_PRICE,
                QUANTITY,
                ORDER_ID,
                PRODUCT_ID
            )
            VALUES (
                V_PRICE,
                ITEM.QUANTITY,
                P_ORDER_ID,
                ITEM.PRODUCT_ID
            );

            UPDATE PRODUCTS
            SET
                STOCK = STOCK - ITEM.QUANTITY,
                STATUS = CASE
                    WHEN STOCK - ITEM.QUANTITY = 0
                    THEN 'OUTOFSTOCK'
                    ELSE STATUS
                END
            WHERE PRODUCT_ID = ITEM.PRODUCT_ID;

        END LOOP;

        -- Commit transaction
        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO SP_CREATE_ORDER;
            RAISE;

    END CreateOrder;


    -- 2. Get Order By Id
PROCEDURE GetOrderById(
    P_ORDER_ID IN ORDERS.ORDER_ID%TYPE
)
AS
    V_ORDER_CURSOR SYS_REFCURSOR;
    V_EXISTING_ORDER_ID ORDERS.ORDER_ID%TYPE;

BEGIN

    SELECT ORDER_ID
    INTO V_EXISTING_ORDER_ID
    FROM ORDERS
    WHERE ORDER_ID = P_ORDER_ID;

    OPEN V_ORDER_CURSOR FOR
        SELECT
            ORDER_ID,
            TOTAL_AMOUNT,
            PAYMENT_METHOD,
            ORDER_STATUS,
            CREATED_AT,
            SHIPPING_ADDRESS,
            CUSTOMER_PHONE_NUMBER,
            CUSTOMER_FULL_NAME,
            USER_ID
        FROM ORDERS
        WHERE ORDER_ID = P_ORDER_ID;

    DBMS_SQL.RETURN_RESULT(V_ORDER_CURSOR);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(
            -20031,
            'Order not found.'
        );

END GetOrderById;

    -- 3. Get Order Items
PROCEDURE GetOrderItems(
    P_ORDER_ID IN ORDERS.ORDER_ID%TYPE
)
AS
    V_ITEMS_CURSOR SYS_REFCURSOR;
    V_EXISTING_ORDER_ID ORDERS.ORDER_ID%TYPE;

BEGIN

    SELECT ORDER_ID
    INTO V_EXISTING_ORDER_ID
    FROM ORDERS
    WHERE ORDER_ID = P_ORDER_ID;

    OPEN V_ITEMS_CURSOR FOR
        SELECT
            OI.ORDER_ITEM_ID,
            OI.PRODUCT_ID,
            P.NAME AS PRODUCT_NAME,
            OI.UNIT_PRICE,
            OI.QUANTITY
        FROM ORDER_ITEMS OI
        JOIN PRODUCTS P
            ON P.PRODUCT_ID = OI.PRODUCT_ID
        WHERE OI.ORDER_ID = P_ORDER_ID;

    DBMS_SQL.RETURN_RESULT(V_ITEMS_CURSOR);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(
            -20031,
            'Order not found.'
        );

END GetOrderItems;

     PROCEDURE GetAllOrders AS
    V_CURSOR SYS_REFCURSOR;
BEGIN
    OPEN V_CURSOR FOR
        SELECT
            ORDER_ID,
            TOTAL_AMOUNT,
            PAYMENT_METHOD,
            ORDER_STATUS,
            CREATED_AT,
            UPDATED_AT,
            SHIPPING_ADDRESS,
            CUSTOMER_PHONE_NUMBER,
            CUSTOMER_FULL_NAME,
            USER_ID
        FROM ORDERS
        ORDER BY CREATED_AT DESC;

    DBMS_SQL.RETURN_RESULT(V_CURSOR);
END GetAllOrders;

PROCEDURE UpdateOrderStatus(
    P_ORDER_ID     IN ORDERS.ORDER_ID%TYPE,
    P_ORDER_STATUS IN ORDERS.ORDER_STATUS%TYPE
)
AS
    V_OLD_STATUS ORDERS.ORDER_STATUS%TYPE;
BEGIN
    SAVEPOINT SP_UPDATE_ORDER_STATUS;

    IF P_ORDER_STATUS IS NULL
       OR P_ORDER_STATUS NOT IN ('PENDING', 'DELIVERED', 'CANCELLED') THEN
        RAISE_APPLICATION_ERROR(-20032, 'Invalid order status.');
    END IF;

    BEGIN
        SELECT ORDER_STATUS
        INTO V_OLD_STATUS
        FROM ORDERS
        WHERE ORDER_ID = P_ORDER_ID
        FOR UPDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20031, 'Order not found.');
    END;

    IF V_OLD_STATUS <> 'PENDING' THEN
        RAISE_APPLICATION_ERROR(
            -20033,
            'Only pending orders can change status.'
        );
    END IF;

    IF P_ORDER_STATUS = 'PENDING' THEN
        RAISE_APPLICATION_ERROR(
            -20034,
            'Order is already pending.'
        );
    END IF;

    IF P_ORDER_STATUS = 'CANCELLED' THEN
        FOR IT IN (
            SELECT PRODUCT_ID, QUANTITY
            FROM ORDER_ITEMS
            WHERE ORDER_ID = P_ORDER_ID
            ORDER BY PRODUCT_ID
        )
        LOOP
            UPDATE PRODUCTS
            SET STOCK = STOCK + IT.QUANTITY,
                STATUS = 'AVAILABLE',
                UPDATED_AT = CURRENT_TIMESTAMP
            WHERE PRODUCT_ID = IT.PRODUCT_ID;
        END LOOP;
    END IF;

    UPDATE ORDERS
    SET ORDER_STATUS = P_ORDER_STATUS,
        UPDATED_AT   = CURRENT_TIMESTAMP
    WHERE ORDER_ID = P_ORDER_ID;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO SP_UPDATE_ORDER_STATUS;
        RAISE;
END UpdateOrderStatus;

END Orders_Package;
/