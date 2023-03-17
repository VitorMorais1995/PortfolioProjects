-- Let's take a look an overall look at our data
SELECT 
	*
FROM 
	Houses_Nash..Nash_Housing


--------------------------------------------------------------------------------------------------------------
-- Let's beggin our work in cleaning the data
-- First, we will standardize Date Format

SELECT
	SaleDate,
	SaleDateConverted
FROM
	Houses_Nash..Nash_Housing

ALTER TABLE
	Houses_Nash..Nash_Housing
	ADD SaleDateConverted Date

UPDATE 
	Houses_Nash..Nash_Housing
SET
	SaleDateConverted = CONVERT(Date,SaleDate)


--------------------------------------------------------------------------------------------------------------
-- Now, let's take a look at the Populate Property Address Data

--Checkin if there are any nulls
SELECT
	PropertyAddress
FROM
	Houses_Nash..Nash_Housing
WHERE
	PropertyAddress IS NULL


--let's take care of these nulls
SELECT
	*
FROM
	Houses_Nash..Nash_Housing
ORDER BY 
	ParcelId

-- let's take a closer look at these nulls, and qe will use a SELF JOIN to do it
SELECT
	A.ParcelId, 
	A.PropertyAddress, 
	B.ParcelID, 
	B.PropertyAddress
FROM
	Houses_Nash..Nash_Housing AS A
JOIN
	Houses_Nash..Nash_Housing AS B
	ON A.PArcelID = B.ParcelID
	AND A.[UniqueId] <> B.[UniqueID]
WHERE
	A.PropertyAddress IS NULL


-- let's populate the nulls
SELECT
	A.ParcelId, 
	A.PropertyAddress, 
	B.ParcelID, 
	B.PropertyAddress,
	ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM
	Houses_Nash..Nash_Housing AS A
JOIN
	Houses_Nash..Nash_Housing AS B
	ON A.PArcelID = B.ParcelID
	AND A.[UniqueId] <> B.[UniqueID]
WHERE
	A.PropertyAddress IS NULL

-- now, let's update the table with these new values
UPDATE
	A
SET
	PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM
	Houses_Nash..Nash_Housing AS A
JOIN
	Houses_Nash..Nash_Housing AS B
	ON A.PArcelID = B.ParcelID
	AND A.[UniqueId] <> B.[UniqueID]
WHERE
	A.PropertyAddress IS NULL

-- After the update we tested if the nulls were gone and they were, now we can move on


--------------------------------------------------------------------------------------------------------------
-- now, let's brake down the whole address into individual columns (Adress, City, Sate)

SELECT
	PropertyAddress
FROM
	Houses_Nash..Nash_Housing
--WHERE
--	PropertyAddress IS NULL

SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
	SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM
	Houses_Nash..Nash_Housing

-- now, we have to create two new columns again and add their values

ALTER TABLE
	Houses_Nash..Nash_Housing
ADD 
	PropertySplitAddress NVARCHAR(255)

UPDATE 
	Houses_Nash..Nash_Housing
SET
	PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)


ALTER TABLE
	Houses_Nash..Nash_Housing
ADD 
	PropertySplitCity NVARCHAR(255)
UPDATE 
	Houses_Nash..Nash_Housing
SET
	PropertySplitCity =SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))


-- now, let's check if it worked
SELECT
	*
FROM
	Houses_Nash..Nash_Housing


-- It worked, let's keep moving on
-- we still need to do the same cleaning process for the OwnerAddress, but for ths I'll do a different process
SELECT
	OwnerAddress
FROM
	Houses_Nash..Nash_Housing

SELECT
	PARSENAME(REPLACE(OwnerAddress, ',', '.'),3) AS OwnerSplitState,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'),2) AS OwnerSplitCity,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'),1) AS OwnerSplitAddress
FROM
	Houses_Nash..Nash_Housing




-- now, we have to create two new columns again and add their values
ALTER TABLE
	Houses_Nash..Nash_Housing
ADD 
	OwnerSplitState NVARCHAR(255)

UPDATE 
	Houses_Nash..Nash_Housing
SET
	OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)




ALTER TABLE
	Houses_Nash..Nash_Housing
ADD 
	OwnerSplitAddress NVARCHAR(255)

UPDATE 
	Houses_Nash..Nash_Housing
SET
	OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)




ALTER TABLE
	Houses_Nash..Nash_Housing
ADD 
	OwnerSplitCity NVARCHAR(255)

UPDATE 
	Houses_Nash..Nash_Housing
SET
	OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)


-- Now, let's check if it worked

SELECT
	*
FROM
	Houses_Nash..Nash_Housing


--------------------------------------------------------------------------------------------------------------
-- now, let's change de Y and N to Yes or No in SoldAsVacant field
SELECT
	DISTINCT(SoldAsVacant),
	COUNT(SoldAsVacant)
FROM
	Houses_Nash..Nash_Housing
GROUP BY
	SoldAsVacant
ORDER BY
	2


-- let's use a CASE statment to fix this
SELECT
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END
FROM
	Houses_Nash..Nash_Housing


-- now, let's update our table
UPDATE
	Houses_Nash..Nash_Housing
SET 
	SoldAsVacant = CASE 
					WHEN SoldAsVacant = 'Y' THEN 'Yes'
					WHEN SoldAsVacant = 'N' THEN 'No'
					ELSE SoldAsVacant
					END

-- the last step is just to check if it right

--------------------------------------------------------------------------------------------------------------
-- now, we will remove duplicates

WITH
	RowNumCTE AS (
SELECT
	*,
	ROW_NUMBER() 
	OVER
	(
	PARTITION BY ParcelId,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
	ORDER BY	
				 UniqueID
	) row_num
FROM
	Houses_Nash..Nash_Housing
--ORDER BY 
--	ParcelID
)
DELETE
FROM
	RowNumCTE
WHERE
	row_num > 1


--------------------------------------------------------------------------------------------------------------
-- now, let's delete some unused columns
SELECT
	*
FROM
	Houses_Nash..Nash_Housing

ALTER TABLE
	Houses_Nash..Nash_Housing
DROP COLUMN
	OwnerAddress,
	TaxDistrict,
	PropertyAddress
