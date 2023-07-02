/**
Cleaning Data in SQL
*/

--Renamed SaleDate Column
EXEC sp_rename 'NashvilleHousing.Sale Date','SaleDate','COLUMN'

--Renamed Unnamed:0 Column
EXEC sp_rename 'NashvilleHousing.Unnamed: 0','UniqueID','COLUMN'

--Removing empty spaces in the beginning of the property address column and updating it
select [Property Address] , LTRIM([Property Address])
from NashvilleHousing
where [Property Address] like ' %'

UPDATE NashvilleHousing
SET [Property Address] = LTRIM([Property Address])
WHERE [Property Address] LIKE ' %'

------------------------------------------------------------------------------------------------------------------------------------------------------------------

/** 
	Standardize the date format
	-- Sale Date is in the datatype 'datetime' but in the data the time serves no purpose so we want to convert it to only date format
*/

-- Changing data type of SaleDate to Date
ALTER TABLE NashvilleHousing
ALTER Column SaleDate Date

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
	Populate property Address data
	-- some addresses have null values
	-- when we order/sort the data by parcel ID, we notice that the parcel Ids are same for the same addresses
	-- so for a parcel Id with a null address, we can check if there is a same parcel Id with a given address and set it to the null address
*/

--Checking for null addresses

Select [Parcel ID], [Property Address], [Owner Name]
FROM NashvilleHousing
where [Property Address] is NULL
Order by [Parcel ID]

-- Query below outputs those parcel ids that appear more than once along with their addresses

Select [Parcel ID], [Property Address]
From NashvilleHousing
Where [Parcel ID] IN (
	SELECT [Parcel ID]
	FROM NashvilleHousing
	GROUP BY [Parcel ID]
	HAVING COUNT([Parcel ID])>1
)
ORDER BY [Parcel ID]

-- self joining the table by parcel Id and unique ID and checking
-- for a given address for every null address where both have same Parcel Ids
-- isnull function shows the column for the addresses that will be set for null addresses in table a

SELECT a.[Parcel ID], a.[Property Address], b.[Parcel ID],b.[Property Address],
ISNULL(a.[Property Address], b.[Property Address])
from NashvilleHousing a
JOIN NashvilleHousing b
ON a.[Parcel ID] = b.[Parcel ID]
and a.UniqueID <> b.UniqueID
WHERE a.[Property Address] IS NULL

-- updating the null addresses
-- run the above query to check for any values left
-- (only rows with null addreses in both tables should be displayed)

UPDATE a
SET [Property Address] = ISNULL(a.[Property Address], b.[Property Address])
FROM NashvilleHousing a
JOIN NashvilleHousing b
ON a.[Parcel ID] = b.[Parcel ID]
and a.UniqueID <> b.UniqueID

-- for those addresses with null values, we can input some data

UPDATE a
SET [Property Address] = ISNULL(a.[Property Address], 'NULL')
FROM NashvilleHousing a
JOIN NashvilleHousing b
ON a.[Parcel ID] = b.[Parcel ID]
and a.UniqueID <> b.UniqueID

------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
	Breaking out property address into Individual Columns (Street number, Street name)
*/

-- adding the 2 new tables into NashvilleHousing
ALTER TABLE NashvilleHousing
ADD Street_Number varchar(50)

Alter Table NashvilleHousing
ADD Street_Name nvarchar(255)

EXEC sp_rename 'NashvilleHousing.Street_Name','StreetName','COLUMN'

-- creating a cte with case statements to output 2 new columns
with cte_temp as(
select UniqueID,
CASE
	WHEN [Property Address] = '0' THEN '-'
	WHEN [Property Address] Like '[0-9]%' THEN SUBSTRING([Property Address], 1,CHARINDEX(' ', [Property Address]))
	WHEN [Property Address] LIKE '[A-Za-z]%' THEN '-'
	WHEN [Property Address] is NULL THEN '-'
END as 'street_number',
CASE
	WHEN [Property Address] = '0' THEN [Property Address]
	WHEN [Property Address] Like '[0-9]%' THEN SUBSTRING([Property Address],CHARINDEX(' ', [Property Address])+1, LEN([Property Address]))
	WHEN [Property Address] LIKE '[A-Za-z]%' THEN [Property Address]
	WHEN [Property Address] is NULL THEN [Property Address]
END as 'street_name'
From NashvilleHousing
)

-- updating the columns in NashvilleHousing
UPDATE NashvilleHousing
set NashvilleHousing.StreetNum= street_number
FROM cte_temp
WHERE NashvilleHousing.UniqueID = cte_temp.UniqueID

--formatting the data

Update NashvilleHousing
set StreetName = LTRIM(StreetName)
--set StreeNum = LTRIM(StreetNum)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
	Making sure all 'Y' and 'N' have been replaced to 'Yes' and 'No' respectively in the 'Sold as Vacant' column
*/

SELECT DISTINCT([Sold As Vacant])
FROM NashvilleHousing

UPDATE NashvilleHousing
SET [Sold As Vacant] = 
CASE
	WHEN [Sold As Vacant] = 'Y' THEN 'Yes'
	WHEN [Sold As Vacant] = 'N' THEN 'No'
	ELSE [Sold As Vacant]
END

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
	Removing Duplicates
	
*/

-- We need to partition the data on things unique to each row (such as UniqueID)
--the below select statement will output the uniue rows with a row_number = 1 and those rows that are repeated will have a output value of row_number = 2

with row_num_cte as(
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY [Parcel ID],
				[Property Address],
				[Sale Price],
				SaleDate,
				[Legal Reference]
				order by UniqueID
				) row_num
FROM NashvilleHousing
)

-- Delete all those duplicate rows with a row_number value>1
select*
from row_num_cte
where row_num>1

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
	Delete Unused Columns
*/

select * from NashvilleHousing

ALTER TABLE NASHVILLEHOUSING
DROP COLUMN [Tax District], image


