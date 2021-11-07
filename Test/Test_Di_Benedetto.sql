USE MASTER
GO

DROP DATABASE IF EXISTS DB_TEST_DIBENEDETTO

CREATE DATABASE DB_TEST_DIBENEDETTO; --creazione del nuovo database

GO
USE DB_TEST_DIBENEDETTO
GO

--creazione delle tabelle

CREATE TABLE PROPRIETARI(
CodF VARCHAR(255) NOT NULL PRIMARY KEY,
Nome varchar(255),
Residenza varchar(255)
);

CREATE TABLE ASSICURAZIONI(
CodAss VARCHAR(255) NOT NULL PRIMARY KEY,
Nome varchar(255),
Sede varchar(255)
);

CREATE TABLE SINISTRI(
CodS VARCHAR(255) NOT NULL PRIMARY KEY,
Localita varchar(255),
Data date
);

CREATE TABLE AUTO (
Targa varchar(255) NOT NULL PRIMARY KEY,
Marca varchar(255),
Cilindrata DECIMAL,
Potenza DECIMAL,
CodF VARCHAR(255) FOREIGN KEY REFERENCES PROPRIETARI(CodF),
CodAss VARCHAR(255) FOREIGN KEY REFERENCES ASSICURAZIONI(CodAss)
);


CREATE TABLE AUTOCOINVOLTE(
CodS VARCHAR(255) NOT NULL FOREIGN KEY REFERENCES SINISTRI(CodS),
Targa varchar(255) NOT NULL FOREIGN KEY REFERENCES AUTO(Targa),
ImportoDelDanno DECIMAL
);

-- creazione di una tabella in cui memorizzare i dati da importare in csv

CREATE TABLE BULK_TABLE(
PROPRIETARICodF VARCHAR(255) NOT NULL,
PROPRIETARiNome varchar(255),
PROPRIETARIResidenza varchar(255),
ASSICURAZIONICodAss VARCHAR(255) NOT NULL,
ASSICURAZIONINome varchar(255),
ASSICURAZIONISede varchar(255),
SINISTRICodS VARCHAR(255) NOT NULL,
SINISTRILocalita varchar(255),
SINISTRIData date,
AUTOTarga varchar(255) NOT NULL,
AUTOMarca varchar(255),
AUTOCilindrata DECIMAL,
AUTOPotenza DECIMAL,
AUTOCodF VARCHAR(255),
AUTOCodAss VARCHAR(255),
AUTOCOINVOLTECodS VARCHAR(255) NOT NULL,
AUTOCOINVOLTETarga varchar(255) NOT NULL,
AUTOCOINVOLTEImportoDelDanno DECIMAL
);

BULK INSERT BULK_TABLE --inserimento dei dati nella tabella
    FROM 'percorso_locale\Test\input\Dati.csv' --da inserire il percorso locale in cui viene salvata la cartella Test
    WITH
    (
    ERRORFILE = 'percorso_locale\Test\Errors.csv', --da inserire il percorso in cui viene salvata la cartella Test
    FIELDTERMINATOR = ';',
    FORMAT = 'CSV',
    KEEPNULLS,
    MAXERRORS = 0, --al primo errore viene annullata l'importazione e generato il log
    ROWTERMINATOR = '\n'
    );

--trasferimento dei dati dalla tabella di import alle singole tabelle

INSERT INTO PROPRIETARI(CodF, Nome, Residenza) 
(SELECT PROPRIETARICodF, PROPRIETARINome, PROPRIETARIResidenza FROM BULK_TABLE
WHERE PROPRIETARICodF is not null and PROPRIETARICodF <> '');

INSERT INTO ASSICURAZIONI(CodAss, Nome, Sede)
SELECT ASSICURAZIONICodAss, ASSICURAZIONINome, ASSICURAZIONISede FROM BULK_TABLE
WHERE ASSICURAZIONICodAss is not null and ASSICURAZIONICodAss <> '';

INSERT INTO SINISTRI(CodS, Localita, Data)
SELECT SINISTRICodS, SINISTRILocalita, SINISTRIData FROM BULK_TABLE
WHERE SINISTRICodS is not null and SINISTRICodS <> '';

INSERT INTO AUTO(Targa, Marca, Cilindrata, Potenza, CodF, CodAss)
SELECT AUTOTarga, AUTOMarca, AUTOCilindrata, AUTOPotenza, AUTOCodF, AUTOCodAss
FROM BULK_TABLE WHERE AUTOTarga is not null and AUTOTarga <> '';

INSERT INTO AUTOCOINVOLTE(CodS, Targa, ImportoDelDanno)
SELECT AUTOCOINVOLTECodS, AUTOCOINVOLTETarga, AUTOCOINVOLTEImportoDelDanno FROM BULK_TABLE
WHERE AUTOCOINVOLTECodS is not null and AUTOCOINVOLTECodS <> ''
AND AUTOCOINVOLTETarga is not null and AUTOCOINVOLTETarga <> '';

DROP TABLE BULK_TABLE; --eliminazione della tabella di import

--query

/*
--1) Targa e Marca delle Auto di cilindrata superiore a 2000 cc o di potenza superiore a 120 CV
SELECT AUTO.Targa, AUTO.Marca
FROM AUTO
WHERE Cilindrata > 2000 OR Potenza > 120;

--2) Nome del proprietario e Targa delle Auto di cilindrata superiore a 2000 cc oppure di potenza superiore a 120 CV
SELECT PROPRIETARI.Nome, AUTO.Targa
FROM AUTO
JOIN PROPRIETARI ON PROPRIETARI.CodF = AUTO.CodF
WHERE Cilindrata > 2000 OR Potenza > 120;

--3) Targa e Nome del proprietario delle Auto di cilindrata superiore a 2000 cc oppure di potenza superiore a 120 CV, assicurate presso la “SARA”
SELECT AUTO.Targa, PROPRIETARI.Nome
FROM AUTO
JOIN PROPRIETARI ON PROPRIETARI.CodF = AUTO.CodF
JOIN ASSICURAZIONI ON ASSICURAZIONI.CodAss = AUTO.CodAss
WHERE (Cilindrata > 2000 OR Potenza > 120)
AND ASSICURAZIONI.Nome = 'SARA';

--4) Targa e Nome del proprietario delle Auto assicurate presso la “SARA” e coinvolte in sinistri il 20/01/02
SELECT AUTO.Targa, PROPRIETARI.Nome
FROM AUTO
JOIN PROPRIETARI ON PROPRIETARI.CodF = AUTO.CodF
JOIN ASSICURAZIONI ON ASSICURAZIONI.CodAss = AUTO.CodAss
JOIN AUTOCOINVOLTE ON AUTO.Targa = AUTOCOINVOLTE.Targa
JOIN SINISTRI ON SINISTRI.CodS = AUTOCOINVOLTE.CodS
WHERE ASSICURAZIONI.Nome = 'SARA'
AND SINISTRI.Data = '2002-01-20';

--5) Per ciascuna Assicurazione, il nome, la sede ed il numero di auto assicurate
SELECT ASSICURAZIONI.Nome, ASSICURAZIONI.Sede, COUNT(AUTO.Targa) AS NumeroAutoAssicurate
FROM ASSICURAZIONI
JOIN AUTO ON ASSICURAZIONI.CodAss = AUTO.CodAss
GROUP BY ASSICURAZIONI.Nome,ASSICURAZIONI.Sede;

--6) Per ciascuna auto “Fiat”, la targa dell’auto ed il numero di sinistri in cui è stata coinvolta
SELECT AUTO.Targa, COUNT(SINISTRI.CodS) AS NumeroSinistri
FROM AUTO
JOIN AUTOCOINVOLTE ON AUTO.Targa = AUTOCOINVOLTE.Targa
JOIN SINISTRI ON SINISTRI.CodS = AUTOCOINVOLTE.CodS
WHERE AUTO.Marca = 'FIAT'
GROUP BY AUTO.Targa;

--7) Per ciascuna auto coinvolta in più di un sinistro, la targa dell’auto, il nome dell’Assicurazione, ed il totale dei danni riportati
SELECT AUTO.Targa, ASSICURAZIONI.Nome, SUM(AUTOCOINVOLTE.ImportoDelDanno) AS TotaleDanni
FROM AUTO
JOIN AUTOCOINVOLTE ON AUTO.Targa = AUTOCOINVOLTE.Targa
JOIN SINISTRI ON SINISTRI.CodS = AUTOCOINVOLTE.CodS
JOIN ASSICURAZIONI ON ASSICURAZIONI.CodAss = AUTO.CodAss
GROUP BY AUTO.Targa, ASSICURAZIONI.Nome
HAVING COUNT(SINISTRI.CodS)>1;

--8) CodF e Nome di coloro che possiedono più di un’auto
SELECT PROPRIETARI.CodF, PROPRIETARI.Nome
FROM PROPRIETARI
JOIN AUTO ON PROPRIETARI.CodF = AUTO.CodF
GROUP BY PROPRIETARI.CodF, PROPRIETARI.Nome
HAVING COUNT(AUTO.Targa) > 1;

--9) La targa delle auto che non sono state coinvolte in sinistri dopo il 20/01/2021
SELECT AUTO.Targa
FROM AUTO
WHERE AUTO.Targa NOT IN (SELECT AUTO.targa
                         FROM AUTO
                         JOIN AUTOCOINVOLTE ON AUTO.Targa = AUTOCOINVOLTE.Targa
                         JOIN SINISTRI ON SINISTRI.CodS = AUTOCOINVOLTE.CodS
                         WHERE SINISTRI.Data > '2021-01-20');

--10) Il codice dei sinistri in cui non sono state coinvolte auto con cilindrata inferiore a 2000 cc
SELECT SINISTRI.CodS
FROM SINISTRI
WHERE SINISTRI.CodS NOT IN (SELECT SINISTRI.cods
                            FROM SINISTRI
                            JOIN AUTOCOINVOLTE ON SINISTRI.CodS = AUTOCOINVOLTE.CodS
                            JOIN AUTO ON AUTOCOINVOLTE.Targa = AUTO.Targa
                            WHERE AUTO.Cilindrata < 2000);

--per auto coinvolte in sinistri prima del 20/01/2021 con proprietario residente in una citta diversa dalla sede dell'assicurazione rivalutare il danno del 10%

--salvataggio della tab originale

SELECT * INTO AUTOCOINV_ORIG FROM AUTOCOINVOLTE;

-- aggiornamento della tabella con la rivalutazione del danno
UPDATE AUTOCOINVOLTE SET AUTOCOINVOLTE.ImportoDelDanno = AUTOCOINVOLTE.ImportoDelDanno + (AUTOCOINVOLTE.ImportoDelDanno * 0.1)
from AUTOCOINVOLTE
JOIN AUTO ON AUTO.Targa = AUTOCOINVOLTE.Targa
JOIN ASSICURAZIONI ON ASSICURAZIONI.CodAss = AUTO.CodAss
JOIN SINISTRI ON SINISTRI.CodS = AUTOCOINVOLTE.CodS
JOIN PROPRIETARI ON PROPRIETARI.CodF = AUTO.CodF
WHERE SINISTRI.Data < '2021-01-20'
AND PROPRIETARI.Residenza <> ASSICURAZIONI.Sede;

-- per le auto coinvolte in sinistri mostrare targa, proprietario e per ogni sinistro dire se c'è stata rivalutazione e di quanto

CREATE TABLE TO_EXP(
Targa VARCHAR(255),
CodF VARCHAR(255),
CodS varchar(255),
Rivalutazione VARCHAR(5),
ImportoDelDanno DECIMAL
)

INSERT INTO TO_EXP (Targa, CodF, CodS, ImportoDelDanno) (
SELECT AUTO.Targa, PROPRIETARI.CodF, AUTOCOINVOLTE.CodS, (AUTOCOINVOLTE.ImportoDelDanno - AUTOCOINV_ORIG.ImportoDelDanno)
FROM AUTO
JOIN PROPRIETARI ON PROPRIETARI.CodF = AUTO.CodF 
JOIN AUTOCOINVOLTE ON AUTO.Targa = AUTOCOINVOLTE.Targa
JOIN AUTOCOINV_ORIG ON AUTOCOINVOLTE.Targa = AUTOCOINV_ORIG.Targa AND AUTOCOINVOLTE.CodS = AUTOCOINV_ORIG.CodS);

UPDATE TO_EXP SET TO_EXP.Rivalutazione = CASE
WHEN TO_EXP.ImportoDelDanno > 0 THEN 'Yes'
WHEN TO_EXP.ImportoDelDanno = 0 THEN 'No'
END;

EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.Jet.OLEDB.4.0', N'AllowInProcess', 1
GO 
EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.Jet.OLEDB.4.0', N'DynamicParameters', 1
GO 
sp_configure 'show advanced options', 1;  
RECONFIGURE;
GO 
sp_configure 'Ad Hoc Distributed Queries', 1;  
RECONFIGURE;  
GO
--Salvataggio in excel della query 9
INSERT INTO OPENROWSET(
'Microsoft.Jet.OLEDB.4.0',
'Database=percorso_locale\Test\processed\Export.xlsx;','select * from [FOGLIO1$]') --da inserire il percorso in cui viene salvata la cartella Test
SELECT AUTO.Targa
FROM AUTO
WHERE AUTO.Targa NOT IN (SELECT AUTO.targa
                         FROM AUTO
                         JOIN AUTOCOINVOLTE ON AUTO.Targa = AUTOCOINVOLTE.Targa
                         JOIN SINISTRI ON SINISTRI.CodS = AUTOCOINVOLTE.CodS
                         WHERE SINISTRI.Data > '2021-01-20');

--Salvataggio in excel di proprietari, targhe auto coinvolte in sinistri con rivalutazione si/no e importo rivalutato
INSERT INTO OPENROWSET(
'Microsoft.Jet.OLEDB.4.0',
'Database=percorso_locale\Test\processed\Export.xlsx;','select * from [FOGLIO2$]')--da inserire il percorso in cui viene salvata la cartella Test
SELECT * FROM TO_EXP;
*/

-- Creare una tabella in cui storicizzare la variazione dell'importo di ogni veicolo
CREATE TABLE AUTOCOINVOLTE_HISTORY(
CodS VARCHAR(255),
Targa varchar(255),
ImportoDelDanno DECIMAL,
DataVariazione datetime NOT NULL DEFAULT GETDATE(), --colonna in cui salvare la data in cui avviene la variazione
Utente VARCHAR(255) --colonna in cui salvare l'utente che inserisce la variazione
);

DROP TRIGGER IF EXISTS Trigger_Auto_Coinvolte;
GO
CREATE TRIGGER Trigger_Auto_Coinvolte --creazione di un trigger che ad ogni update salva un record nella tabella di storico
ON AUTOCOINVOLTE
AFTER UPDATE
AS BEGIN
IF EXISTS(SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
BEGIN
INSERT INTO AUTOCOINVOLTE_HISTORY SELECT inserted.* , GETDATE(), SYSTEM_USER FROM inserted
END
END;


/*Per ridurre i tempi di consultazione della tabella AUTO e, di conseguenza, ridurre il rischio di deadlock, è possibile indicizzare la
tabella tramite il comando CREATE INDEX indice_auto ON AUTO(Targa);
*/

/* per prevenire deadlock è opportuno mantenere brevi le transazioni (usando anche gli indici e altri strumenti di query optimizer),
usare il NOLOCK per dati che vengono modificati poco frequentemente, ridurre il numero di letture, settare opportunamente la deadlock priority
*/

/*per capire quale tabella sia in lock è possibile lanciare la query
select parts.object_id from sys.dm_tran_locks locks join sys.partitions parts on locks.resource_associated_entity_id = parts.hobt_id;
da cui si ottiene l'id della tabella, per ottenere il nome è necessario lanciare select object_name(id_ottenuto)
*/