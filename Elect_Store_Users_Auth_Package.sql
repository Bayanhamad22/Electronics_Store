CREATE OR REPLACE PACKAGE Users_Auth_Package AS

    PROCEDURE RegisterUser(
        P_EMAIL         IN USERS.EMAIL%TYPE,
        P_PHONE_NUMBER  IN USERS.PHONE_NUMBER%TYPE,
        P_FULL_NAME     IN USERS.FULL_NAME%TYPE,
        P_PASSWORD_HASH IN USERS.PASSWORD_HASH%TYPE
    );

    PROCEDURE GetUserByEmail(
        P_EMAIL IN USERS.EMAIL%TYPE
    );

END Users_Auth_Package;
/


CREATE OR REPLACE PACKAGE BODY Users_Auth_Package AS

    PROCEDURE RegisterUser(
        P_EMAIL         IN USERS.EMAIL%TYPE,
        P_PHONE_NUMBER  IN USERS.PHONE_NUMBER%TYPE,
        P_FULL_NAME     IN USERS.FULL_NAME%TYPE,
        P_PASSWORD_HASH IN USERS.PASSWORD_HASH%TYPE
    )
    AS
    BEGIN
        INSERT INTO USERS (
            EMAIL,
            PHONE_NUMBER,
            FULL_NAME,
            PASSWORD_HASH,
            USER_ROLE,
            ACCOUNT_STATUS,
            IS_DELETED
        )
        VALUES (
            LOWER(TRIM(P_EMAIL)),
            P_PHONE_NUMBER,
            P_FULL_NAME,
            P_PASSWORD_HASH,
            'CUSTOMER',
            'ACTIVE',
            'N'
        );

        COMMIT;
    END RegisterUser;
    
        PROCEDURE GetUserByEmail(
        P_EMAIL IN USERS.EMAIL%TYPE
    )
    AS
        P_CURSOR SYS_REFCURSOR;
    BEGIN
        OPEN P_CURSOR FOR
            SELECT
                USER_ID AS UserId,
                EMAIL AS Email,
                PHONE_NUMBER AS PhoneNumber,
                PROFILE_IMG_URL AS ProfileImgUrl,
                PASSWORD_HASH AS PasswordHash,
                FULL_NAME AS FullName,
                ACCOUNT_STATUS AS AccountStatus,
                USER_ROLE AS UserRole,
                IS_DELETED AS IsDeleted
            FROM USERS
            WHERE EMAIL = LOWER(TRIM(P_EMAIL));

        DBMS_SQL.RETURN_RESULT(P_CURSOR);
    END GetUserByEmail;

END Users_Auth_Package;
/