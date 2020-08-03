-------------------------
--1)- Create User table
-------------------------

CREATE TABLE UberUSER
(
  UberID       varchar(15)     NOT NULL,
  FName        varchar(50)     NOT NULL,
  LName        varchar(50)     NOT NULL,
  PhNo         int        NOT NULL,
  Email        varchar(50)     NOT NULL,
  Address      varchar(50)     NOT NULL,
  DOB          DATE        NOT NULL,

  PRIMARY KEY(UberID)
); 

--------------------------
--2)- Create Customer table
--------------------------
CREATE TABLE Customer
(
  CID               varchar(15) NOT NULL,
  CustomerType      varchar(15) NOT NULL ,

  PRIMARY KEY(CID),
  FOREIGN KEY (CID) REFERENCES UberUser(UberID) ON DELETE CASCADE
);

DROP TABLE driver;

--3)- Create Driver table
----------------------
----------------------
CREATE TABLE Driver
(
  DID     varchar(15)      NOT NULL,
  SSN          int          NOT NULL,
  DLNo         varchar(50)      NOT NULL,
  DLExpiry     DATE        NOT NULL,

  PRIMARY KEY(DID),
  FOREIGN KEY (DID) REFERENCES UberUser(UberID) ON DELETE CASCADE
);

-----------------------
--4)- Create Vehicle table
-----------------------
CREATE TABLE Vehicle 
(
  VID             varchar(15)    NOT NULL,
  DrID             varchar(50)    NOT NULL,
  ModelN          varchar(50)    NOT NULL,
  Color           varchar(20)    NOT NULL,
  ManufYear       int           NOT NULL,
  PurDate         DATE          NOT NULL,
  Active          varchar(18)        NOT NULL,
  Condition       varchar(15)    NOT NULL, 
  Cpty              int        NOT NULL,
  InsuranceNo     varchar(15)    NOT NULL,
  InsuranceExpiry varchar(15)    NOT NULL,
  LastChecked     DATE        NOT NULL,

  PRIMARY KEY(VID),
  FOREIGN KEY (DrID) REFERENCES Driver(DID) ON DELETE CASCADE
);

-----------------------
--5)- Create TripRequests table
-----------------------
CREATE TABLE TripRequests  
(
  TripID       varchar(15)    NOT NULL,
  CID          varchar(50)    NOT NULL,
  DID          varchar(50)    NOT NULL,
  TripType     varchar(50)    NOT NULL,
  PickupLoc    varchar(50)    NOT NULL,
  DropoffLoc   varchar(50)    NOT NULL,
  Distance      float      NOT NULL,
  EstFare      float      NOT NULL,
  TID          varchar(15)    NOT NULL,

  PRIMARY KEY(TripID),
  FOREIGN KEY (TID) REFERENCES PaymentMethod(TID) ON DELETE CASCADE,
  FOREIGN KEY (CID) REFERENCES Customer(CID) ON DELETE CASCADE,
  FOREIGN KEY (DID) REFERENCES Driver(DID)  ON DELETE CASCADE
);
-------------------------
--6)- Create CompletedTrips table
-------------------------

CREATE TABLE CompletedTrips  
(
  TripID            varchar(15)    NOT NULL,
  DriverArrivedAt   TIMESTAMP          NOT NULL,
  PickupTime        TIMESTAMP          NOT NULL,
  DropoffTime       TIMESTAMP          NOT NULL,
  duration          int            NOT NULL,
  ActFare           float      NOT NULL,
  Tip               float      NOT NULL,
  Surge        float     NULL,

  PRIMARY KEY(TripID),
  FOREIGN KEY (TripID) REFERENCES TripRequests(TripID) ON DELETE CASCADE
);
-------------------------
--7)- Create IncompleteTrips table
-------------------------

CREATE TABLE IncompleteTrips  
(
  TripID            varchar(15)    NOT NULL,
  BookingTime       TIMESTAMP                   NOT NULL, 
  CancelTime        TIMESTAMP          NOT NULL, 
  Reason            varchar(30)            NOT NULL,

PRIMARY KEY(TripID),
FOREIGN KEY (TripID) REFERENCES TripRequests(TripID) ON DELETE CASCADE
);


-----------------------
--8)- Create PaymentMethod table
-----------------------
CREATE TABLE PaymentMethod
(
  TID          varchar(50)     NOT NULL, 
  CardNo       int        NOT NULL,
  CVV          int        NOT NULL,    
  ExpiryDate	 DATE           NOT NULL, 
  AccType      varchar(50)    NOT NULL,
  CardType     varchar(50)    NOT NULL,
  BillingAdd   varchar(50)    NOT NULL,

  PRIMARY KEY(TID)
);


-----------------------
--9)- Create PersonalPayment table
-----------------------
CREATE TABLE PersonalPayment  
(
  TID           varchar(15)    NOT NULL,
  NameOnCard    varchar(50)    NOT NULL,

  PRIMARY KEY(TID),
  FOREIGN KEY (TID) REFERENCES PaymentMethod(TID) ON DELETE CASCADE
);

-------------------------
--10)- Create BusinessPayment table
-------------------------
CREATE TABLE BusinessPayment  
(
  TID           varchar(15)    NOT NULL,
  CompanyName   varchar(50)    NOT NULL,

  PRIMARY KEY(TID),
  FOREIGN KEY (TID) REFERENCES PaymentMethod(TID) ON DELETE CASCADE
);

-------------------------
--11)- Create Rating table
-------------------------

CREATE TABLE Rating  
(
  TripID               varchar(15)    NOT NULL,
  DriverRating      int        NOT NULL,
  CustomerRating    int        NOT NULL,  
  DriverFeedback    varchar(15)    NOT NULL,
  CustomerFeedback  varchar(15)    NOT NULL,

  PRIMARY KEY(TripID),
  FOREIGN KEY (TripID) REFERENCES CompletedTrips(TripID) ON DELETE CASCADE
);

-------------------------
--12)- Create Shift table
-------------------------


CREATE TABLE Shift  
(
  DID           varchar(15)    NOT NULL,
  DT          DATE           NOT NULL,
  LoginTime     TIMESTAMP                   NOT NULL, 
  LogoutTime    TIMESTAMP          NOT NULL, 

  PRIMARY KEY(DID, DT),
  FOREIGN KEY (DID) REFERENCES Driver(DID) ON DELETE CASCADE
);

-------------------------
--13)- Create Offers table
-------------------------

CREATE TABLE Offers
(
  CID            varchar(15)    NOT NULL,
  PromoCode      varchar(15)    NOT NULL,
  PromoDiscount  float      NOT NULL,

  PRIMARY KEY(CID),
  FOREIGN KEY (CID) REFERENCES Customer(CID) ON DELETE CASCADE
);







-- Stored Procedures---

/* Procedure that will calculate the average rating of the driver */
create or replace PROCEDURE Average_Rating AS

CURSOR DrivRating IS SELECT AVG(R.DriverRating) as AvgRating, T.DID FROM TripRequests T, Rating R WHERE T.TripID=R.TripID GROUP BY T.DID;
thisRating DrivRating%ROWTYPE;

BEGIN
OPEN DrivRating;
LOOP
  FETCH DrivRating INTO thisRating;
  EXIT WHEN (DrivRating%NOTFOUND);
  dbms_output.put_line(thisRating.AvgRating || ' is the Average rating for the driver ID:' || thisRating.DID);

END LOOP;
CLOSE DrivRating;
END;

begin 
Average_Rating;

end;


SET SERVEROUTPUT ON

/* Procedure that will calculate the Total fare for the ride */
create or replace PROCEDURE Calculate_Fare(Base_fare IN number, Service_Tax IN number, Cost_per_mile IN number, Cost_per_min IN number) AS
--DECLARE



CURSOR Trip_total_fare IS
SELECT * FROM TripRequests T, CompletedTrips CT WHERE T.TripID=CT.TripID;

thisTotalFare TripRequests.EstFare%TYPE;
thisTrip CompletedTrips%ROWTYPE;

BEGIN
OPEN Trip_total_fare;
LOOP
  FETCH Trip_total_fare INTO thisTrip;
  EXIT WHEN (Trip_total_fare%NOTFOUND);
  --thisTrip.duration:= thisTrip.DropoffTime  - thisTrip.PickupTime
  thisTotalFare:= (Base_fare + Service_Tax + Cost_per_mile*thisTrip.Distance + Cost_per_min*thisTrip.duration )*(1 + thisTrip.Surge);
  dbms_output.put_line(thisTotalFare || ' is the total fare for the Trip ID:' || thisTrip.TripID ;

END LOOP;
CLOSE Trip_total_fare;
END;





/* Procedure that will calculate the average rating of the driver */
create or replace PROCEDURE Average_Rating AS
DECLARE
thisRating RATING%ROWTYPE;

CURSOR DrivRating IS
SELECT AVG(R.DriverRating) as AvgRating, T.DID FROM TripRequests T, Rating R WHERE T.TripID=R.TripID
 GROUP BY T.DID;

BEGIN
OPEN DrivRating;
LOOP
  FETCH DrivRating INTO thisRating;
  EXIT WHEN (DrivRating%NOTFOUND);
  dbms_output.put_line(thisRating.AvgRating || ' is the Average rating for the driver ID:' || thisRating.DID) ;

END LOOP;
CLOSE DrivRating;
END;


--- Triggers  ---
/* Trigger for DL Expiry */
create or replace TRIGGER DL_Renewal


/* Trigger for Insurance Expiry */
create or replace TRIGGER Insurance_Renewal

