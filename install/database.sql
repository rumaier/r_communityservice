CREATE TABLE IF NOT EXISTS `r_communityservice` (
  `identifier` varchar(46) NOT NULL,
  `tasks` smallint(6) DEFAULT NULL,
  `items` longtext DEFAULT NULL,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
