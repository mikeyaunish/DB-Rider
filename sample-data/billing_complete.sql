CREATE DATABASE  IF NOT EXISTS `billing_complete` /*!40100 DEFAULT CHARACTER SET latin1 */;
USE `billing_complete`;
-- MySQL dump 10.13  Distrib 5.7.14, for Win64 (x86_64)
--
-- Host: localhost    Database: billing_complete
-- ------------------------------------------------------
-- Server version	5.7.14

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `address`
--

DROP TABLE IF EXISTS `address`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `address` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Street1` char(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',
  `Street2` char(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',
  `City` char(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',
  `StateProv` char(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',
  `PostalCode` char(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',
  `Country` char(25) COLLATE latin1_general_ci NOT NULL DEFAULT '',
  PRIMARY KEY (`ID`)
) ENGINE=MyISAM AUTO_INCREMENT=595 DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `address`
--

LOCK TABLES `address` WRITE;
/*!40000 ALTER TABLE `address` DISABLE KEYS */;
INSERT INTO `address` VALUES (189,'485 Rolling Rd','','Lasalle','QC','H8R 3C2','Canada'),(203,'8788 E 64th Ave','','Vancouver','BC','V6R 1N3','Canada'),(208,'27 Spring St','','Woodstock','ON','N4S 2K1','Canada'),(313,'70 W Main St','','Vancouver','BC','V5Z 3S8','Canada'),(590,'357 W Mount Royal Ave','','Longueuil','QC','J4M 2A8','Canada'),(591,'123 Euclid Ave #9396','','Nanaimo','BC','V9R 1C9','Canada'),(592,'1251 E Main St #990','','Quebec','QC','G1H 1A6','Canada'),(593,'259 W 17th St #39','','Beresford','NB','E8K 1B7','Canada'),(594,'9 Route 38','','Port Coquitlam','BC','V3C 2Z4','Canada');
/*!40000 ALTER TABLE `address` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `company`
--

DROP TABLE IF EXISTS `company`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `company` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',
  `MainContact` int(11) DEFAULT NULL,
  `BillAddress` int(11) DEFAULT NULL,
  `ShipAddress` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`,`Name`)
) ENGINE=MyISAM AUTO_INCREMENT=598 DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `company`
--

LOCK TABLES `company` WRITE;
/*!40000 ALTER TABLE `company` DISABLE KEYS */;
INSERT INTO `company` VALUES (198,'A All In One Construction',214,189,189),(211,'A & H Sptc Systems & Matl Inc',228,203,313),(216,'Alliance Construction Co Inc',233,208,0),(284,'Alex Fries & Bros Inc',302,594,591),(320,'Royal Title Service Inc',338,313,0),(593,'Curtiss Wright Corp',615,590,0),(594,'Phelps Tool & Die Co Inc',616,591,0),(595,'Factory Mattress Outlet',617,592,0);
/*!40000 ALTER TABLE `company` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `inventory`
--

DROP TABLE IF EXISTS `inventory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `inventory` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `date` date DEFAULT NULL,
  `item` int(11) DEFAULT NULL,
  `quantity` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventory`
--

LOCK TABLES `inventory` WRITE;
/*!40000 ALTER TABLE `inventory` DISABLE KEYS */;
INSERT INTO `inventory` VALUES (1,'2017-10-04',60,500.00),(2,'2017-10-13',1,100.00),(3,'2017-10-13',34,10.00);
/*!40000 ALTER TABLE `inventory` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `invoice`
--

DROP TABLE IF EXISTS `invoice`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `invoice` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Status` int(11) DEFAULT NULL,
  `Company` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=MyISAM AUTO_INCREMENT=68 DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci COMMENT='This is a comment for the invoice table';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `invoice`
--

LOCK TABLES `invoice` WRITE;
/*!40000 ALTER TABLE `invoice` DISABLE KEYS */;
INSERT INTO `invoice` VALUES (67,2515,216),(62,2510,211),(63,2511,198),(64,2512,284),(65,2513,320),(66,2514,595);
/*!40000 ALTER TABLE `invoice` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `invoicestatus`
--

DROP TABLE IF EXISTS `invoicestatus`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `invoicestatus` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `InvoiceNo` int(11) NOT NULL DEFAULT '0',
  `Status` set('Created','Re-Created','Cancelled','Printed','Paid') COLLATE latin1_general_ci NOT NULL DEFAULT '',
  `Timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=MyISAM AUTO_INCREMENT=2516 DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `invoicestatus`
--

LOCK TABLES `invoicestatus` WRITE;
/*!40000 ALTER TABLE `invoicestatus` DISABLE KEYS */;
INSERT INTO `invoicestatus` VALUES (2514,66,'Re-Created','2017-11-05 05:32:51'),(2515,67,'Re-Created','2017-11-05 05:43:23'),(2513,65,'Re-Created','2017-11-05 05:32:18'),(2510,62,'Re-Created','2017-11-05 05:25:52'),(2511,63,'Re-Created','2017-11-05 05:26:03'),(2512,64,'Re-Created','2017-11-05 05:26:37');
/*!40000 ALTER TABLE `invoicestatus` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item`
--

DROP TABLE IF EXISTS `item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `item` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Description` varchar(100) COLLATE latin1_general_ci NOT NULL DEFAULT '',
  `PartNo` varchar(30) COLLATE latin1_general_ci NOT NULL DEFAULT '',
  `Price` decimal(10,2) NOT NULL DEFAULT '0.00',
  `Type` int(11) DEFAULT NULL,
  `Company` int(11) NOT NULL DEFAULT '0',
  `PoNo` varchar(30) COLLATE latin1_general_ci NOT NULL DEFAULT '',
  PRIMARY KEY (`ID`)
) ENGINE=MyISAM AUTO_INCREMENT=63 DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item`
--

LOCK TABLES `item` WRITE;
/*!40000 ALTER TABLE `item` DISABLE KEYS */;
INSERT INTO `item` VALUES (1,'Netgear 24 port 10 and 100 switch','JFS524NA',515.00,2,0,' '),(3,'External dual 8mm tape unit','7208-232',450.00,2,0,' '),(4,'APC Uninterruptible Power Supply','BX1000UPS',240.00,2,0,' '),(5,'SMC Network Card','SMC1244TX-CA',10.00,2,0,' '),(20,'Consulting 100','SERVICE-A',100.00,1,0,' '),(24,'Netgear 24 port router.','JFS524NA',515.00,2,0,' '),(21,'Reconfigure wiring closet','WIRECONF',450.00,3,211,' '),(22,'Consulting 75 ','SERVICE-B',75.00,1,0,' '),(23,'Repair broken firewall','FWBROKE',200.00,3,216,' '),(25,'LG 40X12X40 CD writer Serial Number 25HA081523','360-00062',130.00,2,0,' '),(26,'128MB PC-133 Infineon Memory','050-00147',60.00,2,0,' '),(27,'Power Supply Fan','PWRSUP-FAN',5.00,2,0,' '),(28,'Quantum 12GB IDE disk drive.','QUANTUM12GB',125.00,2,0,' '),(29,'80GB 7200RPM Samsung IDE disk drive','SP8004H',185.00,2,0,' '),(30,'Kingston KVR133X64C3 512MB memory module','170055559',115.00,2,0,' '),(31,'LG 48x24x48 CD Read Writer drive.','GCE-8481',105.00,2,0,' '),(32,'Sleek mouse','33L3244',41.73,2,0,' '),(33,'Thinkpad R31','2TPE092',527.00,2,0,' '),(34,'Maxtor 40GB 7200RPM ATA13 disk','E13KVNLE',140.00,2,0,' '),(35,'128MB Main Memory Storage DIMM','FC3002',495.00,2,0,' '),(36,'APC Smart UPS 1500VA Tower','SUA1500',795.00,2,0,' '),(37,'External dual 8mm tape unit','7208-232',450.00,2,0,' '),(38,'Orinoco PCMCIA wireless card','OR1000',97.50,2,0,' '),(39,'Wasp CCD LR Scanner PC/PS2 KDB Wedge. SN#1- WLR703887 SN#2- WLR702609 SN#3- WLR702632','WASPCCDLR',350.00,2,0,' '),(40,'7/14GB Internal 8mm tape (with Mod 500 sled) PO# 139342','FC6390',525.00,2,0,' '),(41,'Logitech wheel mouse USB for connection to Rhoberta\'s laptop.','5L930995',25.00,2,0,' '),(42,'Okidata Pacemark 4410 dot matrix printer.','61800901',4350.00,2,0,' '),(43,'Dlink 8 Port 10/100 switch','DLINKSWITCH',42.75,2,0,' '),(44,'15 Foot USB printer cable.','USB-15FT',21.39,2,0,' '),(45,'APC BX800VA Uninteruptible Power Supply.','BX800VA',145.00,2,0,' '),(46,'Maxtor 250GB 7200RPM disk at cost from Memory Express. S/N: L50N00XG','6L250R0',117.65,2,0,' '),(47,'Maxtor 80GB 7200 RPM 8MB Disk drive. SN L22X263G.','6L080P0',80.00,2,0,' '),(48,'Panaflo 80mm High Flow fan','FBA08A12H1A',22.50,2,0,' '),(49,'Samsung 40GB 2.5 inch 5400 RPM laptop disk','MP0402H',90.00,2,0,' '),(50,'BenQ FP72G+S 17in Digital LCD Monitor for main server','BENQFP72G+S',250.00,2,0,' '),(51,'Powerline XE102 ethernet bridge','606449036794',115.00,2,0,' '),(52,'CAT5E network cable 50\'','TP0802S16',32.00,2,0,' '),(53,'Thinkpad port replicator II','74P6733-01',75.00,2,0,' '),(54,'Western Digital 160GB 7200RPM 8MB. S/N: WCANMK006621','WD1600JB',81.56,2,0,' '),(55,'Computer Battery','CR2032',8.00,2,0,' '),(56,'Seagate 250GB 7200RPM 16MB SATA drive','ST5250410AS',95.00,2,0,' '),(57,'Antec 380W Power Supply','EA380',70.00,2,0,' '),(58,'Samsung SyncMaster 920BM 19\" Black Monitor. S/N: WJ19H9FPA29050','729507802084',215.20,2,0,' '),(59,'Linksys WRV54G Wireless G Router.','745883556687',185.00,2,0,' '),(60,'Wireless keyboard','WLSKBD100',150.00,2,0,' '),(62,'Remove old router','RTRREMOVE',250.00,3,198,''),(61,'20 inch LCD screen','LCD20',115.00,2,0,' ');
/*!40000 ALTER TABLE `item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `itemtype`
--

DROP TABLE IF EXISTS `itemtype`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `itemtype` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(50) COLLATE latin1_general_ci NOT NULL DEFAULT '',
  PRIMARY KEY (`ID`)
) ENGINE=MyISAM AUTO_INCREMENT=6 DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `itemtype`
--

LOCK TABLES `itemtype` WRITE;
/*!40000 ALTER TABLE `itemtype` DISABLE KEYS */;
INSERT INTO `itemtype` VALUES (1,'Service'),(2,'Product'),(3,'Quote'),(4,'Shipping'),(5,'Miscellaneous');
/*!40000 ALTER TABLE `itemtype` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lineitem`
--

DROP TABLE IF EXISTS `lineitem`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lineitem` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Date` date NOT NULL DEFAULT '0000-00-00',
  `Company` int(11) DEFAULT NULL,
  `Type` int(11) DEFAULT NULL,
  `Item` int(11) DEFAULT NULL,
  `Quantity` decimal(10,2) unsigned DEFAULT '0.00',
  `Description` varchar(1024) COLLATE latin1_general_ci DEFAULT '',
  `Invoice` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=MyISAM AUTO_INCREMENT=52 DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lineitem`
--

LOCK TABLES `lineitem` WRITE;
/*!40000 ALTER TABLE `lineitem` DISABLE KEYS */;
INSERT INTO `lineitem` VALUES (43,'2017-10-14',320,2,1,5.00,'Netgear 24 port router.',65),(42,'2017-10-14',211,2,34,4.00,'replace bad hard drive',62),(39,'2017-10-14',198,2,1,1.00,'Netgear 24 port 10 and 100 switch',63),(40,'2017-10-14',284,2,1,1.00,'Netgear 24 port 10 and 100 switch',64),(35,'2017-10-14',198,2,60,5.00,'Wireless keyboard',63),(36,'2017-10-12',595,2,36,1.00,'APC Smart UPS 1500VA Tower',66),(33,'2017-10-14',211,1,20,2.50,'Reconfigure screen setup ',62),(41,'2017-10-14',216,2,60,20.00,'Wireless keyboard',67),(38,'2017-10-14',198,3,62,3.00,'Remove old router and replace with new fancy one.',63),(37,'2017-10-12',595,1,20,2.50,'Install new UPS and configure ',66),(34,'2017-10-14',284,2,61,2.00,'20 inch LCD screen',64),(44,'2017-10-14',216,3,23,1.00,'fix firewall',67),(45,'2017-10-14',198,2,59,1.00,'Linksys WRV54G Wireless G Router.',63),(46,'2017-10-14',320,1,20,12.00,'Replace all of the routers ',65),(47,'2017-10-14',284,1,20,3.00,'Fix the wiring closet mess',64),(48,'2017-10-14',216,1,20,3.00,'install wireless keyboards for everyone',67);
/*!40000 ALTER TABLE `lineitem` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `person`
--

DROP TABLE IF EXISTS `person`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `person` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `FirstName` varchar(100) NOT NULL DEFAULT '',
  `LastName` varchar(100) NOT NULL DEFAULT '',
  `Address` int(10) unsigned NOT NULL DEFAULT '0',
  `Email` varchar(200) NOT NULL DEFAULT '',
  `Company` int(10) unsigned NOT NULL DEFAULT '0',
  `Phone` varchar(12) NOT NULL DEFAULT '',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=620 DEFAULT CHARSET=latin1 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `person`
--

LOCK TABLES `person` WRITE;
/*!40000 ALTER TABLE `person` DISABLE KEYS */;
INSERT INTO `person` VALUES (214,'Arlette','Torchio',189,'arlette_torchio@hotmail.com',198,'514-459-6883'),(228,'Kaycee','Alaibilla',203,'kaycee.alaibilla@yahoo.com',211,'604-992-6045'),(233,'Harley','Works',208,'harley@cox.net',216,'519-913-7772'),(302,'Tanesha','Tesseneer',594,'tanesha_tesseneer@hotmail.com',284,'416-568-3388'),(338,'Brandon','Geigel',313,'bgeigel@gmail.com',320,'604-940-9313'),(615,'Erin','Delbosque',590,'erin@cox.net',593,'450-316-7813'),(616,'Kassandra','Marushia',591,'kassandra@gmail.com',594,'250-646-6446'),(617,'Leslee','Matsuno',592,'leslee_matsuno@matsuno.org',595,'418-460-5773'),(618,'Daniel','Dobler',593,'ddobler@dobler.com',594,'506-617-2607'),(619,'Antonio','Unruh',594,'antonio.unruh@hotmail.com',595,'604-624-7690');
/*!40000 ALTER TABLE `person` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'billing_complete'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2017-11-05 22:02:12
