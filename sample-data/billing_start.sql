CREATE DATABASE  IF NOT EXISTS `billing_start` /*!40100 DEFAULT CHARACTER SET latin1 */;
USE `billing_start`;
-- MySQL dump 10.13  Distrib 5.7.14, for Win64 (x86_64)
--
-- Host: localhost    Database: billing_start
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
) ENGINE=MyISAM AUTO_INCREMENT=9 DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `address`
--

LOCK TABLES `address` WRITE;
/*!40000 ALTER TABLE `address` DISABLE KEYS */;
INSERT INTO `address` VALUES (1,'485 Rolling Rd','','Lasalle','QC','H8R 3C2','Canada'),(2,'8788 E 64th Ave','','Vancouver','BC','V6R 1N3','Canada'),(3,'27 Spring St','','Woodstock','ON','N4S 2K1','Canada'),(4,'70 W Main St','','Vancouver','BC','V5Z 3S8','Canada'),(5,'357 W Mount Royal Ave','','Longueuil','QC','J4M 2A8','Canada'),(6,'123 Euclid Ave #9396','','Nanaimo','BC','V9R 1C9','Canada'),(7,'1251 E Main St #990','','Quebec','QC','G1H 1A6','Canada'),(8,'259 W 17th St #39','','Beresford','NB','E8K 1B7','Canada'),(9,'9 Route 38','','Port Coquitlam','BC','V3C 2Z4','Canada');
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
) ENGINE=MyISAM AUTO_INCREMENT=8 DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `company`
--

LOCK TABLES `company` WRITE;
/*!40000 ALTER TABLE `company` DISABLE KEYS */;
INSERT INTO `company` VALUES (1,'A All In One Construction',214,189,189),(2,'A & H Sptc Systems & Matl Inc',228,203,313),(3,'Alliance Construction Co Inc',233,208,0),(4,'Alex Fries & Bros Inc',302,594,591),(5,'Royal Title Service Inc',338,313,0),(6,'Curtiss Wright Corp',615,590,0),(7,'Phelps Tool & Die Co Inc',616,591,0),(8,'Factory Mattress Outlet',617,592,0);
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
INSERT INTO `item` VALUES (1,'Netgear 24 port 10 and 100 switch','JFS524NA',515.00,0,0,' '),(3,'External dual 8mm tape unit','7208-232',450.00,0,0,' '),(4,'APC Uninterruptible Power Supply','BX1000UPS',240.00,0,0,' '),(5,'SMC Network Card','SMC1244TX-CA',10.00,0,0,' '),(20,'Consulting 100','SERVICE-A',100.00,0,0,' '),(24,'Netgear 24 port router.','JFS524NA',515.00,0,0,' '),(21,'Reconfigure wiring closet','WIRECONF',450.00,0,0,' '),(22,'Consulting 75 ','SERVICE-B',75.00,0,0,' '),(23,'Repair broken firewall','FWBROKE',200.00,0,0,' '),(25,'LG 40X12X40 CD writer Serial Number 25HA081523','360-00062',130.00,0,0,' '),(26,'128MB PC-133 Infineon Memory','050-00147',60.00,0,0,' '),(27,'Power Supply Fan','PWRSUP-FAN',5.00,0,0,' '),(28,'Quantum 12GB IDE disk drive.','QUANTUM12GB',125.00,0,0,' '),(29,'80GB 7200RPM Samsung IDE disk drive','SP8004H',185.00,0,0,' '),(30,'Kingston KVR133X64C3 512MB memory module','170055559',115.00,0,0,' '),(31,'LG 48x24x48 CD Read Writer drive.','GCE-8481',105.00,0,0,' '),(32,'Sleek mouse','33L3244',41.73,0,0,' '),(33,'Thinkpad R31','2TPE092',527.00,0,0,' '),(34,'Maxtor 40GB 7200RPM ATA13 disk','E13KVNLE',140.00,0,0,' '),(35,'128MB Main Memory Storage DIMM','FC3002',495.00,0,0,' '),(36,'APC Smart UPS 1500VA Tower','SUA1500',795.00,0,0,' '),(37,'External dual 8mm tape unit','7208-232',450.00,0,0,' '),(38,'Orinoco PCMCIA wireless card','OR1000',97.50,0,0,' '),(39,'Wasp CCD LR Scanner PC/PS2 KDB Wedge. SN#1- WLR703887 SN#2- WLR702609 SN#3- WLR702632','WASPCCDLR',350.00,0,0,' '),(40,'7/14GB Internal 8mm tape (with Mod 500 sled) PO# 139342','FC6390',525.00,0,0,' '),(41,'Logitech wheel mouse USB for connection to Rhoberta\'s laptop.','5L930995',25.00,0,0,' '),(42,'Okidata Pacemark 4410 dot matrix printer.','61800901',4350.00,0,0,' '),(43,'Dlink 8 Port 10/100 switch','DLINKSWITCH',42.75,0,0,' '),(44,'15 Foot USB printer cable.','USB-15FT',21.39,0,0,' '),(45,'APC BX800VA Uninteruptible Power Supply.','BX800VA',145.00,0,0,' '),(46,'Maxtor 250GB 7200RPM disk at cost from Memory Express. S/N: L50N00XG','6L250R0',117.65,0,0,' '),(47,'Maxtor 80GB 7200 RPM 8MB Disk drive. SN L22X263G.','6L080P0',80.00,0,0,' '),(48,'Panaflo 80mm High Flow fan','FBA08A12H1A',22.50,0,0,' '),(49,'Samsung 40GB 2.5 inch 5400 RPM laptop disk','MP0402H',90.00,0,0,' '),(50,'BenQ FP72G+S 17in Digital LCD Monitor for main server','BENQFP72G+S',250.00,0,0,' '),(51,'Powerline XE102 ethernet bridge','606449036794',115.00,0,0,' '),(52,'CAT5E network cable 50\'','TP0802S16',32.00,0,0,' '),(53,'Thinkpad port replicator II','74P6733-01',75.00,0,0,' '),(54,'Western Digital 160GB 7200RPM 8MB. S/N: WCANMK006621','WD1600JB',81.56,0,0,' '),(55,'Computer Battery','CR2032',8.00,0,0,' '),(56,'Seagate 250GB 7200RPM 16MB SATA drive','ST5250410AS',95.00,0,0,' '),(57,'Antec 380W Power Supply','EA380',70.00,0,0,' '),(58,'Samsung SyncMaster 920BM 19\" Black Monitor. S/N: WJ19H9FPA29050','729507802084',215.20,0,0,' '),(59,'Linksys WRV54G Wireless G Router.','745883556687',185.00,0,0,' '),(60,'Wireless keyboard','WLSKBD100',150.00,0,0,' '),(62,'Remove old router','RTRREMOVE',250.00,0,0,''),(61,'20 inch LCD screen','LCD20',115.00,0,0,' ');
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
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lineitem`
--

LOCK TABLES `lineitem` WRITE;
/*!40000 ALTER TABLE `lineitem` DISABLE KEYS */;
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
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=latin1 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `person`
--

LOCK TABLES `person` WRITE;
/*!40000 ALTER TABLE `person` DISABLE KEYS */;
INSERT INTO `person` VALUES (1,'Arlette','Torchio',0,'arlette_torchio@hotmail.com',0,'514-459-6883'),(2,'Kaycee','Alaibilla',0,'kaycee.alaibilla@yahoo.com',0,'604-992-6045'),(3,'Harley','Works',0,'harley@cox.net',0,'519-913-7772'),(4,'Tanesha','Tesseneer',0,'tanesha_tesseneer@hotmail.com',0,'416-568-3388'),(5,'Brandon','Geigel',0,'bgeigel@gmail.com',0,'604-940-9313'),(6,'Erin','Delbosque',0,'erin@cox.net',0,'450-316-7813'),(7,'Kassandra','Marushia',0,'kassandra@gmail.com',0,'250-646-6446'),(8,'Leslee','Matsuno',0,'leslee_matsuno@matsuno.org',0,'418-460-5773'),(9,'Daniel','Dobler',0,'ddobler@dobler.com',0,'506-617-2607'),(10,'Antonio','Unruh',0,'antonio.unruh@hotmail.com',0,'604-624-7690');
/*!40000 ALTER TABLE `person` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'billing_start'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2017-11-05 22:09:59
