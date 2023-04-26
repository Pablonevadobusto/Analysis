------------------------------ Standardize Date Format ------------------------------------

SELECT SaleDate
FROM [dbo].[Nashville]

ALTER TABLE [dbo].[Nashville]
ALTER COLUMN SaleDate date;

------------------------------ Populate Property Address data ------------------------------------

;WITH CTE as (
select *
FROM(
select ParcelID
		,PropertyAddress
		,Row_number() OVER (PARTITION BY ParcelID ORDER BY PropertyAddress) rk
FROM [dbo].[Nashville]
where ParcelID in (
select ParcelID
FROM [dbo].[Nashville]
where PropertyAddress is NULL
)
and PropertyAddress is not NULL) a
where rk = 1
)

UPDATE a
SET PropertyAddress = b.PropertyAddress
FROM [dbo].[Nashville] a
	INNER JOIN CTE b
	 ON a.ParcelID = b.ParcelID
WHERE a.PropertyAddress is NULL

------------------------------ Breaking out Address into Individual Columns (address, City, State) ------------------------------------

-- PropertyAddress
SELECT	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address
		,SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as Address
FROM [dbo].[Nashville]


ALTER TABLE [dbo].[Nashville]
ADD PropertySplitAddress nvarchar(255);


ALTER TABLE [dbo].[Nashville]
ADD PropertySplitCity nvarchar(255);

UPDATE [dbo].[Nashville]
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

UPDATE [dbo].[Nashville]
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

-- OwnerAddress

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) as Address
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) as City
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) as State
FROM [dbo].[Nashville]


ALTER TABLE [dbo].[Nashville]
ADD OwnerSplitAddress nvarchar(255);

ALTER TABLE [dbo].[Nashville]
ADD OwnerSplitCity nvarchar(255);

ALTER TABLE [dbo].[Nashville]
ADD OwnerSplitState nvarchar(255);

UPDATE [dbo].[Nashville]
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)


UPDATE [dbo].[Nashville]
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)


UPDATE [dbo].[Nashville]
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

------------------------------ Change Y and N to Yes and No in "Sold as Vacant" field ------------------------------------

select distinct SoldAsVacant
		,COUNT(SoldAsVacant) as CountSoldAsVacant
FROM [dbo].[Nashville]
GROUP BY SoldAsVacant
order by 2

UPDATE [dbo].[Nashville]
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END


------------------------------ Remove Duplicates ------------------------------------

;WITH CTE as(
SELECT *
		,ROW_NUMBER() OVER (PARTITION BY ParcelID
										,PropertyAddress
										,SalePrice
										,SaleDate
										,LegalReference
										ORDER BY UniqueID) row
FROM [dbo].[Nashville]
)

DELETE
FROM CTE 
WHERE row <> 1

------------------------------ Delete Unused Columns ------------------------------------
-- Normally done over Views (not raw data imported)

select * 
FROM [dbo].[Nashville]


ALTER TABLE [dbo].[Nashville]
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress
