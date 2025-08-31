

/*---SHOPINOT: Analyse d’activité en SQL & Recommandation Marketing---*/

/*--- PROJET 1 : Analyse du comportement d’achat ---*/

/*---Quels sont les produits les plus vendus chaque mois ?---*/
with all_products AS(
        SELECT 
            order_id
            , product_name
            , COUNT(quantity) as count_quantity 
        FROM order_item 
        INNER JOIN products
        ON order_item.product_id = products.product_id
    	GROUP BY product_name
), 
products_final AS (   
    SELECT 
        YEAR(order_date ) AS years
        , MONTH( order_date ) as months
        , product_name
        , count_quantity
    FROM orders
    INNER JOIN all_products
    ON orders.order_id = all_products.order_id
    GROUP BY product_name, YEAR(order_date ), MONTH( order_date ) 
    
)
    
SELECT 
    years
    , months
    , product_name
    , MAX(count_quantity) as quantity
FROM products_final
GROUP BY years, months
ORDER BY years, months



/*---Quel est le panier moyen par client ? Pour évaluer la valeur moyenne d’un client.---*/

    --Version simple --

SELECT 
    last_name AS Nom
    , first_name AS Prenom 
    , COUNT(order_id) AS nb_commandes
    , ROUND(AVG(total_amount), 2) AS Panier_moyen 
FROM orders
INNER JOIN customer
ON customer.customer_id = orders.customer_id
GROUP BY orders.customer_id



    --Version optimisée : Quel est le panier moyen pour client spécifique en fonction de lannée choisie  ?
--
SELECT last_name AS Nom,first_name AS Prenom ,  AVG(total_amount) AS Panier_moyen 
FROM orders
INNER JOIN customer
ON customer.customer_id = orders.customer_id
WHERE customer.customer_id = 1500 AND YEAR(order_date) = 2024
GROUP BY orders.customer_id ;


/*---Combien de clients commandent plus d’une fois par mois.---*/

with all_customers AS (
    	/*recuperer les clients ayant plus dun achat par mois*/
        SELECT YEAR(order_date) AS years
    			,MONTH(order_date) AS months
    			, customer_id
    			, COUNT(order_id) AS client_achat_sup
        FROM orders
        GROUP BY YEAR(order_date)
    			, MONTH(order_date)
    			, customer_id
        HAVING COUNT(order_id) > 1
    )
    
SELECT years, months, COUNT(client_achat_sup) AS nombre_client_mensuel
FROM all_customers
GROUP BY years, months;



/*---Quelles sont les heures et jours de la semaine les plus actifs ? ---*/
    --Base de données ne collectait pas l'heure donc nous allons identifier le jour uniquement--

with all_sell_by_day AS(
    SELECT YEAR(order_date) AS years
    		, MONTH(order_date) AS months
            , DAYNAME(order_date) AS jour_commande
            , COUNT(order_id) AS nbre_commande
    FROM orders
    GROUP BY YEAR(order_date), MONTH(order_date), jour_commande 

)

SELECT years
		, months
        , jour_commande
        , MAX(nbre_commande) AS Maxi_commande
FROM all_sell_by_day
GROUP BY years, months 


/*---Quel est le taux de réachat par mois ? ---*/

DROP TEMPORARY TABLE IF EXISTS temp_all_customers_monthly;
DROP TEMPORARY TABLE IF EXISTS temp_all_customers_rebuy;

CREATE TEMPORARY TABLE temp_all_customers_monthly AS
	SELECT 
    	YEAR(order_date) AS years
    	,MONTH(order_date) AS months
        ,COUNT(DISTINCT customer_id) AS nombre_client_mensuel
    FROM orders
    GROUP BY years, months;

CREATE TEMPORARY TABLE temp_all_customers_rebuy AS
with all_customers AS (
    /*recuperer les clients ayant plus dun achat par mois*/
        SELECT YEAR(order_date) AS years
    			, MONTH(order_date) AS months
    			, customer_id
    			, COUNT(order_id) AS client_achat_sup
   
        FROM orders
        GROUP BY YEAR(order_date)
    			, MONTH(order_date)
    			, customer_id
        HAVING COUNT(order_id) > 1
), 
all_customers_rebuy AS (
    SELECT years, months, COUNT(client_achat_sup) AS nombre_client_reachat
    FROM all_customers
    GROUP BY years, months
)
SELECT * FROM all_customers_rebuy;


SELECT 
    temp_all_customers_rebuy.years AS annee
    ,temp_all_customers_rebuy.months AS mois
    ,temp_all_customers_monthly.nombre_client_mensuel AS nombre_client_mensuel
    ,temp_all_customers_rebuy.nombre_client_reachat AS nombre_client_reachat
    ,ROUND((
        temp_all_customers_rebuy.nombre_client_reachat
        /temp_all_customers_monthly.nombre_client_mensuel
    )*100 , 2) AS Taux_reachat_mensuel
FROM temp_all_customers_rebuy
INNER JOIN temp_all_customers_monthly
ON temp_all_customers_rebuy.months=temp_all_customers_monthly.months
GROUP BY annee, mois;

    --Version optimisée--
DROP TEMPORARY TABLE IF EXISTS temp_all_customers_monthly;
DROP TEMPORARY TABLE IF EXISTS temp_all_customers_rebuy;

CREATE TEMPORARY TABLE temp_all_customers_monthly AS
	SELECT 
    	YEAR(order_date) AS years
    	,MONTH(order_date) AS months
        ,COUNT(DISTINCT customer_id) AS nombre_client_mensuel
    FROM orders
    GROUP BY years, months;

CREATE TEMPORARY TABLE temp_all_customers_rebuy AS
with all_customers AS (
    /*recuperer les clients ayant plus dun achat par mois*/
        SELECT YEAR(order_date) AS years
    			,MONTH(order_date) AS months
    			, customer_id
    			, COUNT(order_id) AS client_achat_sup
   
        FROM orders
        GROUP BY YEAR(order_date)
    			, MONTH(order_date)
    			, customer_id
        HAVING COUNT(order_id) > 1
), 
all_customers_rebuy AS (
    SELECT years, months, COUNT(client_achat_sup) AS nombre_client_reachat
    FROM all_customers
    GROUP BY years, months
)
SELECT * FROM all_customers_rebuy;


SELECT 
    temp_all_customers_rebuy.years AS annee
    ,temp_all_customers_rebuy.months AS mois
    , ROUND(
        (temp_all_customers_rebuy.nombre_client_reachat
        /temp_all_customers_monthly.nombre_client_mensuel)*100
        ,2) AS Taux_reachat_annuel
FROM temp_all_customers_rebuy
INNER JOIN temp_all_customers_monthly
ON temp_all_customers_rebuy.months=temp_all_customers_monthly.months
GROUP BY annee, mois;


/*---Quel est le taux de réachat annuel ? ---*/

    --Version simple--
with all_customers AS (
    /*recuperer les clients ayant plus dun achat par mois*/
        SELECT YEAR(order_date) AS years
    			,MONTH(order_date) AS months
    			, customer_id
    			, COUNT(DISTINCT customer_id) AS client_achat_sup
   
        FROM orders
        GROUP BY YEAR(order_date)
    			, MONTH(order_date)
    			, customer_id
        HAVING COUNT(order_id) > 1
), 
all_customers_rebuy AS (
    SELECT years, months, COUNT(client_achat_sup) AS nombre_client_reachat
    FROM all_customers
    GROUP BY years, months
), 
/*Selectionne tous les achats sans exception*/ 
all_customers_monthly AS (
    SELECT COUNT(order_id) AS nombre_client_mensuel
    		,YEAR(order_date) AS years
    		,MONTH(order_date) AS months
    FROM orders
    GROUP BY years, months
), 
count_all_customers_rebuy AS (
    SELECT SUM(nombre_client_reachat) AS count_rebuy
    FROM all_customers_rebuy
), 
count_all_customers_monthly AS (
    SELECT SUM(nombre_client_mensuel) AS count_monthly
    FROM all_customers_monthly
)


SELECT count_rebuy/count_monthly*100 AS Taux_reachat_annuel
FROM count_all_customers_monthly
JOIN count_all_customers_rebuy
ON 1=1;


/*--- PROJET 2 : Analyse des Produits & Catégories ---*/


/*---Quelle est l’évolution mensuelle du chiffre d’affaires ? ---*/

SELECT
    YEAR(order_date) AS Année
    ,MONTH(order_date) AS Mois
    ,SUM(total_amount) AS Chiffre_affaire
FROM
    orders
GROUP BY
 	YEAR(order_date)
	,MONTH(order_date)
;
    -- Tendance du CA-- 
WITH CA_mensuel AS (
SELECT
    YEAR(order_date) AS Année
    ,MONTH(order_date) AS Mois
    ,SUM(total_amount) AS Chiffre_affaire
FROM
    orders
GROUP BY
 	YEAR(order_date)
	,MONTH(order_date)
)
SELECT
	MIN(Chiffre_affaire) AS CA_mensuel_MIN
    ,ROUND(AVG(Chiffre_affaire)) AS CA_mensuel_Moyen
    ,MAX(Chiffre_affaire) AS CA_mensuel_MAX
FROM CA_mensuel
WHERE Mois != 5



/*---Quels produits génèrent le plus de chiffre d’affaires ?---*/

SELECT
	product_name AS Nom_produit
	,SUM(quantity * order_item.unit_price) AS Chiffre_Affaire
FROM order_item
INNER JOIN products
ON order_item.product_id = products.product_id
GROUP BY Nom_produit
ORDER BY Chiffre_Affaire DESC
LIMIT 5


/*--- Quelles catégories de produits performent le mieux ? ---*/

SELECT
	category AS Categorie
	,SUM(quantity) AS Quantité_produit_achété
FROM order_item
INNER JOIN products
ON order_item.product_id = products.product_id
GROUP BY Categorie
ORDER BY Quantité_produit_achété DESC
#LIMIT 1


/*--- Quel est le taux de croissance mensuel des ventes ?  ---*/

    -- Aider par l'IA--
WITH ventes_mensuelles AS (
    SELECT DATE_FORMAT(order_date, '%Y-%m') AS mois,
           SUM(total_amount) AS chiffre_affaires
    FROM orders
    GROUP BY mois
),
croissance AS (
    SELECT 
        mois,
        chiffre_affaires,
        LAG(chiffre_affaires) OVER (ORDER BY mois) AS ca_mois_precedent
    FROM ventes_mensuelles
)
SELECT 
    mois,
    chiffre_affaires,
    ca_mois_precedent,
    ROUND(((chiffre_affaires - ca_mois_precedent) / ca_mois_precedent) * 100, 2) AS taux_croissance
FROM croissance
;

/*--- Quels sont les clients les plus rentables pour Shopino ? ---*/

SELECT
    customer.customer_id AS ID_client
	,CONCAT(first_name,' ', last_name) AS Nom_prenom
    ,COUNT(order_id) AS Nb_commandes
	,SUM(total_amount) AS Total_depenses
FROM orders
INNER JOIN customer
ON orders.customer_id = customer.customer_id
GROUP BY Nom_prenom
ORDER BY total_depense DESC
LIMIT 10


/*--- PROJET 3 : Analyse des Paiements ---*/


/*--- Quel est le mode de paiement le plus utilisé ? ---*/

SELECT
	payment_method AS methode_payement
    ,COUNT(payment_method) AS Nbre_utilisation
FROM payments
GROUP BY payment_method
ORDER BY Nbre_utilisation DESC
LIMIT 1;


/*--- Quel est le taux de succès des paiements par méthode ?---*/

WITH payment_succeded AS(
	SELECT
    	payment_method AS payment_succed
        ,COUNT(payment_method) AS nbre_payment_succed
    FROM payments
    WHERE payment_status = 'succeeded'
    GROUP BY payment_method
)

SELECT
	payment_method AS methode_payement
    , nbre_payment_succed AS Transaction_succès
    , COUNT(payment_method) AS Nbre_transactions
    , ROUND(nbre_payment_succed/COUNT(payment_method)*100,2) AS Taux_succès
FROM payments
INNER JOIN payment_succeded
ON payments.payment_method = payment_succeded.payment_succed
GROUP BY payment_method
;

    -- Version optimisé ( by Chatgpt)
SELECT 
    payment_method,
    COUNT(*) AS total_tentatives,
    SUM(CASE WHEN payment_status = 'Succeeded' THEN 1 ELSE 0 END) AS nb_succes,
    ROUND(SUM(CASE WHEN payment_status = 'Succeeded' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS taux_succes
FROM payments
GROUP BY payment_method
ORDER BY taux_succes DESC;


/*--- Quel est le délai moyen entre commande et paiement (pour les paiements réussis) ?---*/

SELECT
	payment_method AS Methode_payement
	, ROUND(AVG(DATEDIFF(payment_date, order_date))*24) AS Délai_moyen_en_heure
FROM orders
INNER JOIN payments
ON orders.order_id = payments.order_id
WHERE payment_status = 'succeeded'
GROUP BY payment_method
;


/*--- Combien de paiements échouent par semaine ? ---*/

SELECT 
	YEAR(order_date) AS Annee 
    ,MONTH(order_date) AS Mois 
    ,COUNT(payment_id) AS Nbre_transaction_echouee
     
FROM `payments` 
INNER JOIN orders 
ON payments.order_id = orders.order_id 
WHERE payment_status IN ('failed', 'cancelled')
GROUP BY Annee, Mois
;


/*--- Quel est l’impact des paiements échoués sur le chiffre d’affaires manqué ? ---*/

SELECT 
	YEAR(order_date) AS Annee 
    ,MONTH(order_date) AS Mois 
    ,COUNT(payment_id) AS Nbre_transaction_echouee 
    ,SUM(total_amount) AS CA_manque
FROM `payments` 
INNER JOIN orders 
ON payments.order_id = orders.order_id 
WHERE payment_status ='failed'
GROUP BY Annee, Mois
;
    -- Perte annuelle --
SELECT 
	YEAR(order_date) AS Annee
    ,COUNT(payment_id) AS Nbre_transaction_echouee 
    ,MIN(total_amount) AS CA_manque_min
    ,ROUND(AVG(total_amount)) AS CA_manque_moy
    ,MAX(total_amount) AS CA_manque_max
    ,SUM(total_amount) AS CA_manque_total
FROM `payments` 
INNER JOIN orders 
ON payments.order_id = orders.order_id 
WHERE payment_status = 'failed'
GROUP BY Annee
;


/*--- Existe-t-il une corrélation entre le panier moyen et le type de paiement ? ---*/

SELECT 
    COUNT(orders.order_id) AS Nbre_commande
    ,payment_method AS Mode_payement
    ,ROUND(AVG(total_amount), 2) AS Panier_moyen 
FROM orders
INNER JOIN payments
ON payments.order_id = orders.order_id
WHERE payment_status = 'succeeded'
GROUP BY Mode_payement
ORDER BY Panier_moyen DESC
;

/*--- PROJET 4 : Analyse des Retours Produits ---*/


/*--- Quel est le taux de retour global ? ---*/

SELECT 
	COUNT(return_id) AS Produits_retournes 
    ,COUNT(order_item.order_item_id) AS Produits_vendus
    ,ROUND(COUNT(return_id)/COUNT(order_item.order_item_id)*100,2) AS Taux_retour_global
FROM order_item
LEFT JOIN returns
ON order_item.order_item_id = returns.order_item_id
;


/*--- Quels sont les produits les plus retournés ? ---*/

SELECT 
	product_name AS Nom_produit
    ,category AS Categorie
    ,COUNT(category) AS Nbre_produits_retournes
FROM order_item
INNER JOIN returns
ON order_item.order_item_id = returns.order_item_id
INNER JOIN products
ON order_item.product_id = products.product_id
GROUP BY Nom_produit
ORDER BY Nbre_produits_retournes DESC
LIMIT 10
;
     -- Quels sont les produits retournés par categorie ? -- 
SELECT 
	category AS Categorie
    ,COUNT(category) AS Nbre_produits_retournes
FROM order_item
INNER JOIN returns
ON order_item.order_item_id = returns.order_item_id
INNER JOIN products
ON order_item.product_id = products.product_id
GROUP BY category
ORDER BY Nbre_produits_retournes DESC
;


/*--- Quels sont les motifs de retour les plus fréquents ? ---*/

SELECT 
	return_reason AS Raison_retour
    ,COUNT(return_reason) AS Quantite
    ,ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM returns), 2) AS Pourcentage
FROM returns
GROUP BY Raison_retour
ORDER BY Quantite DESC


/*--- Quel est le montant total remboursé aux clients ? ---*/

SELECT
	ROUND(SUM(refund_amount)/1000000, 2) AS Total_rembourses_en_Million
    ,ROUND(AVG(refund_amount), 2) AS Remboursement_Moyen
FROM returns
;
        -- Quel est le montant remboursé par categorie de produit ?  --
SELECT 
	category AS Categorie
	,ROUND(SUM(refund_amount)/1000000, 2) AS Montant_en_Million
FROM order_item
INNER JOIN returns
ON order_item.order_item_id = returns.order_item_id
INNER JOIN products
ON order_item.product_id = products.product_id
GROUP BY Categorie
ORDER BY Montant_en_Million DESC
;
        -- Quel est le montant remboursé par motifs de retour ?
SELECT 
	return_reason AS Raison_retour
	,ROUND(SUM(refund_amount)/1000000, 2) AS Montant_en_Million
FROM returns
GROUP BY return_reason 
ORDER BY Montant_en_Million DESC
;


/*--- Y a-t-il des clients qui retournent fréquemment leurs achats ? ---*/

SELECT 
	customer.customer_id AS Customer_id
    ,CONCAT(first_name, ' ', last_name) AS Nom_client
    ,COUNT(customer.customer_id)  AS Nbre_de_commande
	,COUNT(returns.customer_id)  AS Nbre_de_retour
FROM returns
INNER JOIN customer
ON returns.customer_id = customer.customer_id
GROUP BY Customer_id
HAVING COUNT(returns.customer_id) > 2
ORDER BY Nbre_de_retour DESC
LIMIT 10
;


/*--- Existe-t-il une saisonnalité des retours ? ---*/

SELECT 
	YEAR(return_date) AS Years
    ,MONTH(return_date) AS Months
    ,COUNT(return_id) AS Nbre_produits_retournes
FROM returns
GROUP BY Years, Months
;


/*--- PROJET 5 : Analyse Marketing & Fidélisation ---*/


/*--- Top 10 clients par chiffre d’affaires cumulé ---*/

SELECT 
	customer.customer_id AS ID_Client
    ,CONCAT(first_name, ' ', last_name) AS Nom_client
    ,ROUND(SUM(total_amount)/1000000, 2) AS Chiffre_affaires_cumulé_en_millions
FROM customer
JOIN orders
ON customer.customer_id = orders.customer_id
GROUP BY  Nom_client
ORDER BY Chiffre_affaires_cumulé_en_millions DESC
LIMIT 10
;


/*--- Quels sont les clients actifs, fidèles, ou dormants ---*/

SELECT 
	customer.customer_id  AS ID_client
	,CONCAT(first_name, ' ', last_name) as Nom_client
    ,COUNT(order_id) AS Nbre_commandes
    ,SUM(total_amount) AS Montant_total
    ,MAX(order_date) AS Derniere_date
    ,DATEDIFF('2025-05-13', MAX(order_date)) AS recence_jours
FROM customer
JOIN orders
ON customer.customer_id = orders.customer_id
GROUP BY  Nom_client
ORDER BY Montant_total DESC, Nbre_commandes DESC
LIMIT 10
;


/*--- Taux de fidélisation mensuel ---*/

WITH Monthly_orders AS (
    -- Regrouper les commandes par mois et par client--
    SELECT
        customer_id
        ,YEAR(order_date) AS Years
        ,MONTH(order_date) AS Months
    FROM orders
    GROUP BY customer_id, YEAR(order_date), MONTH(order_date)
),
Fidelity_rate AS (
    -- Calculer le nombre de clients revenant le mois suivant --
    SELECT
        m1.Years,
        m1.Months,
        COUNT(DISTINCT m1.customer_id) AS clients_mois_n,
        COUNT(DISTINCT m2.customer_id) AS clients_mois_n_plus_1 
    FROM Monthly_orders m1
    LEFT JOIN Monthly_orders m2
        ON m1.customer_id = m2.customer_id
        AND m2.Years = m1.Years
        AND m2.Months = m1.Months + 1  
    GROUP BY m1.Years, m1.Months
)
    -- Calculer le taux de fidélisation--
SELECT
    Years AS Annee
    ,Months AS Mois
    ,clients_mois_n AS Nbre_client_Mois_courant
    ,clients_mois_n_plus_1 AS Nbre_client_Mois_suivant 
    ,ROUND((clients_mois_n_plus_1 / clients_mois_n) * 100, 2 ) AS Taux_fidelite
FROM Fidelity_rate
ORDER BY Years, Months
;