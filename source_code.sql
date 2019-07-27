CREATE TABLE transaction_table(
trans_id int(11) UNIQUE,
    account_id int(11),
    date int(11),
    type TEXT,
    operation TEXT,
    amount float(6,1),
    balance float(8,1),
    k_symbol TEXT,
    bank TEXT,
    account int(11),
PRIMARY KEY (trans_id));

ALTER TABLE `loan`
ADD FOREIGN KEY (`account_id`) REFERENCES `account`(`account_id`)
ALTER TABLE `order_table`
ADD FOREIGN KEY (`account_id`) REFERENCES `account`(`account_id`);
ALTER TABLE ` transaction_table `
ADD FOREIGN KEY (`account_id`) REFERENCES `account`(`account_id`);
ALTER TABLE `account`
ADD FOREIGN KEY (`district_id`) REFERENCES `district`(`A1`);
ALTER TABLE `disposition`
ADD FOREIGN KEY (`account_id`) REFERENCES `account`(`account_id`);
ALTER TABLE `disposition`
ADD FOREIGN KEY (`client_id`) REFERENCES `client`(`client_id`);
ALTER TABLE `client`
ADD FOREIGN KEY (`district_id`) REFERENCES `district`(`A1`);
ALTER TABLE `card`
ADD FOREIGN KEY (`disp_id`) REFERENCES `disposition`(`disp_id`);

DROP FUNCTION IF EXISTS cal_age;
CREATE FUNCTION cal_age (birth_num int(11)) 
RETURNS int(2)
RETURN 99-(birth_num DIV 10000);

DROP FUNCTION IF EXISTS cal_gender;
DELIMITER //
CREATE FUNCTION cal_gender ( birth_num INT )
RETURNS VARCHAR(6)
BEGIN
   DECLARE month_born INT;
   DECLARE gender VARCHAR(6);
   SET month_born = birth_num DIV 100;
   SET month_born = MOD(month_born,100);
   IF month_born <= 12 THEN
   	SET gender = "Male";
   ELSE
   	SET gender = "Female";
   END IF;
   RETURN gender;
END; //
DELIMITER ;

DROP TABLE IF EXISTS loan_df;
CREATE TABLE loan_df
SELECT loan.account_id AS account_id, loan.loan_id AS loan_id, loan.amount AS amount,loan.status AS status
FROM loan
GROUP BY loan.account_id;

DROP TABLE IF EXISTS client_df;
CREATE TABLE client_df
SELECT client.client_id AS client_id, client.district_id AS district_id,cal_age(client.birth_number) AS AGE, cal_gender(client.birth_number) AS GENDER
FROM client
GROUP BY client.client_id;
DROP TABLE IF EXISTS trans_df;
CREATE TABLE trans_df
SELECT transaction_table.account_id AS account_id, SUM(transaction_table.amount) AS sum_amount, SUM(transaction_table.balance) AS sum_balance
FROM transaction_table
WHERE (transaction_table.date DIV 10000) > 97
GROUP BY transaction_table.account_id;

DROP TABLE IF EXISTS card_df;
CREATE TABLE card_df
SELECT card.disp_id AS disp_id, card.type AS type
FROM card
GROUP BY card.disp_id;

DROP TABLE IF EXISTS district_df;
CREATE TABLE district_df
SELECT district.A1 AS district_id, district.A2 AS district_name, district.A3 AS region, district.A11 AS avg_salary, ABS(district.A12-district.A13) AS unemp_diff_95_96, district.A14 AS entrepreneur_per_1000
FROM district
WHERE district.A12 > 0 AND district.A13 > 0
GROUP BY district.A1;

DROP TABLE IF EXISTS disposition_df;
CREATE TABLE disposition_df
SELECT disposition.account_id AS account_id, disposition.disp_id AS disp_id,disposition.type AS type,disposition.client_id AS client_id
FROM disposition
GROUP BY disposition.disp_id;

DROP TABLE IF EXISTS disposition_client;
CREATE TABLE disposition_client
SELECT disposition_df.client_id AS client_id, disposition_df.account_id AS account_id, disposition_df.disp_id AS disposition_id, disposition_df.type AS type, client_df.district_id AS district_id, client_df.AGE AS age, client_df.GENDER AS gender
FROM disposition_df
JOIN client_df
ON disposition_df.client_id = client_df.client_id;

DROP TABLE IF EXISTS disposition_client_card;
CREATE TABLE disposition_client_card
SELECT disposition_client.disposition_id AS disposition_id, disposition_client.client_id AS client_id, disposition_client.account_id AS account_id, disposition_client.type AS type, disposition_client.district_id AS district_id, disposition_client.age AS age, disposition_client.gender AS gender, card_df.type AS card_type
FROM disposition_client
JOIN card_df
ON disposition_client.disposition_id = card_df.disp_id;

DROP TABLE IF EXISTS disposition_client_card_district;
CREATE TABLE disposition_client_card_district
SELECT disposition_client_card.district_id AS district_id, disposition_client_card.disposition_id AS disposition_id, disposition_client_card.client_id AS client_id, disposition_client_card.account_id AS account_id, disposition_client_card.type AS type, disposition_client_card.age AS age, disposition_client_card.gender AS gender, disposition_client_card.card_type AS card_type, district_df.district_name AS district_name, district_df.region AS region, district_df.avg_salary AS avg_salary, district_df.unemp_diff_95_96 AS unemp_diff_95_96, district_df.entrepreneur_per_1000 AS entrepreneur_per_1000
FROM disposition_client_card
JOIN district_df
ON disposition_client_card.district_id = district_df.district_id;

DROP TABLE IF EXISTS disposition_client_card_district_trans;
CREATE TABLE disposition_client_card_district_trans
SELECT disposition_client_card_district.account_id AS account_id, disposition_client_card_district.district_id AS district_id, disposition_client_card_district.disposition_id AS disposition_id, disposition_client_card_district.client_id AS client_id,  disposition_client_card_district.type AS type, disposition_client_card_district.age AS age, disposition_client_card_district.gender AS gender, disposition_client_card_district.card_type AS card_type, disposition_client_card_district.district_name AS district_name, disposition_client_card_district.region AS region, disposition_client_card_district.avg_salary AS avg_salary, disposition_client_card_district.unemp_diff_95_96 AS unemp_diff_95_96, disposition_client_card_district.entrepreneur_per_1000 AS entrepreneur_per_1000,
trans_df.sum_amount AS sum_amount, trans_df.sum_balance AS sum_balance
FROM disposition_client_card_district
JOIN trans_df
ON disposition_client_card_district.account_id = trans_df.account_id;

DROP TABLE IF EXISTS finalTable;
CREATE TABLE finalTable
SELECT disposition_client_card_district_trans.account_id AS account_id, disposition_client_card_district_trans.type AS disposition_type, disposition_client_card_district_trans.age AS age, disposition_client_card_district_trans.gender AS gender, disposition_client_card_district_trans.card_type AS card_type, disposition_client_card_district_trans.district_name AS district_name, disposition_client_card_district_trans.avg_salary AS avg_salary, disposition_client_card_district_trans.unemp_diff_95_96 AS unemp_rate, disposition_client_card_district_trans.entrepreneur_per_1000 AS no_of_entre,
disposition_client_card_district_trans.sum_amount AS transaction_sum, 
loan_df.amount AS loan_amount, loan_df.status AS loan_status
FROM disposition_client_card_district_trans
JOIN loan_df
ON disposition_client_card_district_trans.account_id = loan_df.account_id;

SELECT * 
FROM finaltable
WHERE finaltable.transaction_sum > 1000000 AND finaltable.avg_salary > 10000 AND finaltable.loan_status = "A" AND finaltable.age > 25 AND finaltable.age <= 65;

SELECT *
FROM finaltable
WHERE (finaltable.transaction_sum BETWEEN 150000 AND 1000000) AND finaltable.avg_salary > 6000 AND (finaltable.loan_status = "A" OR finaltable.loan_status = "C") AND (finaltable.age BETWEEN 25 AND 55) AND finaltable.unemp_rate < 0.8;

SELECT *
FROM finaltable
WHERE finaltable.avg_salary > 6000 AND (finaltable.loan_status = "B" OR finaltable.loan_status = "D") AND finaltable.age > 35 AND finaltable.no_of_entre > 100;
