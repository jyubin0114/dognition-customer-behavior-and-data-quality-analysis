### PART 1-1: DATA CLEANING ###

# Make cleaned dataset
# complete_tests
WITH cleaned_complete_tests AS (
SELECT	DISTINCT *
FROM	complete_tests
)
SELECT	*
FROM	cleaned_complete_tests;

# dogs
WITH cleaned_dogs AS (
SELECT 	DISTINCT *
FROM	dogs
)
SELECT	*
FROM	dogs;

# exam_answers
WITH cleaned_exam_answers AS (
SELECT	DISTINCT *
FROM	exam_answers
WHERE	dog_guid IS NOT NULL AND
		end_time IS NOT NULL
)
SELECT	*
FROM	cleaned_exam_answers;

# reviews
WITH cleaned_reviews AS (
SELECT	DISTINCT *
FROM	reviews
)
SELECT	*
FROM	cleaned_reviews;

# site_activities
WITH cleaned_site_activities AS (
SELECT	DISTINCT *
FROM	site_activities
)
SELECT	*
FROM	cleaned_site_activities;

# users
WITH cleaned_users AS (
SELECT	DISTINCT *
FROM	users
)
SELECT	*
FROM	cleaned_users;

# find values that occur multiple times
# check which row with the same user_guid is more informative
WITH cleaned_users AS (
SELECT	DISTINCT *
FROM	users
)
SELECT		B.*
FROM		(
			SELECT		user_guid, COUNT(*) AS count
			FROM		cleaned_users
			GROUP BY	user_guid
			HAVING		COUNT(*) > 1
			) AS A
LEFT JOIN	cleaned_users AS B
ON			A.user_guid = B.user_guid
ORDER BY	user_guid;

# the results show that the only difference is 'utc_correction' (a number or #N/A)
# Now keep only the informative rows
WITH cleaned_users AS (
SELECT	DISTINCT *
FROM	users
),
ranked_users AS (
SELECT	*,
		ROW_NUMBER() OVER (
		PARTITION BY user_guid
		ORDER BY CASE WHEN utc_correction != '#N/A' THEN 0 ELSE 1 END DESC
		) AS rn
FROM	cleaned_users
)
SELECT	*
FROM	ranked_users
WHERE 	rn = 1;

### PART 1-2: FIND PK ###

# complete_tests (177667 rows)
WITH cleaned_complete_tests AS (
SELECT	DISTINCT *
FROM	complete_tests
)
SELECT 		created_at, updated_at, dog_guid, user_guid, test_name, COUNT(*) AS count
FROM		cleaned_complete_tests
GROUP BY	created_at, updated_at, dog_guid, user_guid, test_name
HAVING		COUNT(*) > 1;

# dogs
WITH cleaned_dogs AS (
SELECT 	DISTINCT *
FROM	dogs
)
SELECT		dog_guid, COUNT(*) AS count
FROM		cleaned_dogs
GROUP BY	dog_guid
HAVING		COUNT(*) > 1;

# exam_answers
WITH cleaned_exam_answers AS (
SELECT	DISTINCT *
FROM	exam_answers
WHERE	dog_guid IS NOT NULL AND
		end_time IS NOT NULL
)
SELECT		script_detail_id, start_time, end_time, loop_number, dog_guid, COUNT(*) AS count
FROM		cleaned_exam_answers
GROUP BY	script_detail_id, start_time, end_time, loop_number, dog_guid
HAVING		COUNT(*) > 1;

# reviews
WITH cleaned_reviews AS (
SELECT	DISTINCT *
FROM	reviews
)
SELECT		created_at, dog_guid, test_name, COUNT(*) AS count
FROM		cleaned_reviews
GROUP BY	created_at, dog_guid, test_name
HAVING		COUNT(*) > 1;

# site_activities
# check if ‘description’, ‘created_at’, ‘user_guid’ are unique
# if the result is empty, these three columns can be a Primary Key
WITH cleaned_site_activities AS (
SELECT	DISTINCT *
FROM	site_activities
)
SELECT		description, created_at, user_guid, COUNT(*) AS count
FROM		cleaned_site_activities
GROUP BY	description, created_at, user_guid
HAVING		COUNT(*) > 1;

# users
WITH cleaned_users AS (
SELECT	DISTINCT *
FROM	users
),
ranked_users AS (
SELECT	*,
		ROW_NUMBER() OVER (
		PARTITION BY user_guid
		ORDER BY CASE WHEN utc_correction != '#N/A' THEN 0 ELSE 1 END DESC
		) AS rn
FROM	cleaned_users
)
SELECT		user_guid, COUNT(*) AS count
FROM		ranked_users
WHERE 		rn = 1
GROUP BY	user_guid
HAVING		COUNT(*) > 1;


### PART 2: Searching Potential Issues ###
# complete_tests
WITH cleaned_complete_tests AS (
SELECT	DISTINCT *
FROM	complete_tests
)
SELECT	DISTINCT test_name, subcategory_name
FROM	cleaned_complete_tests;
# FOUND POTENTIAL ISSUES: subcateogry should be recategorized. no ~game


# dogs
WITH cleaned_dogs AS (
SELECT 	DISTINCT *
FROM	dogs
)
SELECT	*
FROM	cleaned_dogs
WHERE	created_at > updated_at;
# FOUND POTENTIAL ISSUES: created time is more recent than updated time

WITH cleaned_dogs AS (
SELECT 	DISTINCT *
FROM	dogs
)
SELECT		breed,
			MAX(weight)
FROM		cleaned_dogs
GROUP BY	breed
ORDER BY	MAX(weight) DESC;
# FOUND POTENTIAL ISSUES: Shih Tzu can't be 250lbs

# exam_answers
WITH cleaned_exam_answers AS (
SELECT	DISTINCT *
FROM	exam_answers
WHERE	dog_guid IS NOT NULL AND
		end_time IS NOT NULL
)
SELECT	*
FROM	cleaned_exam_answers
WHERE	start_time > end_time;
# FOUND POTENTIAL ISSUES: start time is more recent than end time

WITH cleaned_exam_answers AS (
SELECT	DISTINCT *
FROM	exam_answers
WHERE	dog_guid IS NOT NULL AND
		end_time IS NOT NULL
)
SELECT	*
FROM	cleaned_exam_answers
WHERE	subcategory_name = test_name;
# FOUND POTENTIAL ISSUES: 1416285 rows which has same subcategory_name with test_name. Needs to recategorize it or rename test

# reviews
WITH cleaned_reviews AS (
SELECT	DISTINCT *
FROM	reviews
)
SELECT		user_guid, dog_guid, test_name, COUNT(*) AS count
FROM		cleaned_reviews
GROUP BY	user_guid, dog_guid, test_name
HAVING		count > 1;
# FOUND POTENTIAL ISSUES: 180 reviews are from same user, dog about the same test

# site_activities
WITH cleaned_site_activities AS (
SELECT	DISTINCT *
FROM	site_activities
)
SELECT	*
FROM	cleaned_site_activities
WHERE	description = 'User has made it to id 404';
# ??

WITH cleaned_site_activities AS (
SELECT	DISTINCT *
FROM	site_activities
)
SELECT		dog_guid, user_guid
FROM		cleaned_site_activities
GROUP BY	dog_guid, user_guid
ORDER BY	dog_guid;

WITH cleaned_site_activities AS (
SELECT	DISTINCT *
FROM	site_activities
)
SELECT	DISTINCT membership_id
FROM	cleaned_site_activities;


# users
WITH cleaned_users AS (
SELECT	DISTINCT *
FROM	users
),
ranked_users AS (
SELECT	*,
		ROW_NUMBER() OVER (
		PARTITION BY user_guid
		ORDER BY CASE WHEN utc_correction != '#N/A' THEN 0 ELSE 1 END DESC
		) AS rn
FROM	cleaned_users
)
SELECT	*
FROM	ranked_users
WHERE	last_active_at < updated_at;
# FOUND POTENTIAL ISSUES: updated time is more recent than last active (??)

WITH cleaned_users AS (
SELECT	DISTINCT *
FROM	users
),
ranked_users AS (
SELECT	*,
		ROW_NUMBER() OVER (
		PARTITION BY user_guid
		ORDER BY CASE WHEN utc_correction != '#N/A' THEN 0 ELSE 1 END DESC
		) AS rn
FROM	cleaned_users
)
SELECT	membership_id, membership_type, subscribed, free_start_user
FROM	ranked_users
WHERE	subscribed = 0 AND membership_type != 4;
# FOUND POTENTIAL ISSUES: if a user doesn't have a paid subscription, membership type should be 4.
# but there are 5013 rows that subscribed = 0 and membership_type != 4


### PART 3-a: ANALYZE SIGN_UPS ###
WITH cleaned_users AS (
SELECT	DISTINCT *
FROM	users
),
ranked_users AS (
SELECT	*,
		ROW_NUMBER() OVER (
		PARTITION BY user_guid
		ORDER BY CASE WHEN utc_correction != '#N/A' THEN 0 ELSE 1 END DESC
		) AS rn
FROM	cleaned_users
)
SELECT		YEAR(created_at) AS YEAR,
			MONTH(created_at) AS MONTH,
            COUNT(*) AS total_number,
            ROUND(SUM(CASE WHEN membership_type = 1 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS tyoe1,
            ROUND(SUM(CASE WHEN membership_type = 2 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS type2,
            ROUND(SUM(CASE WHEN membership_type = 3 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS type3,
            ROUND(SUM(CASE WHEN membership_type = 4 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS type4,
            ROUND(SUM(CASE WHEN membership_type = 5 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS type5
FROM		ranked_users
GROUP BY	YEAR(created_at), MONTH(created_at)
ORDER BY	YEAR, MONTH;

# Dognition official launch announcement was on February 2013, that's why there are only 3 values total from Dec 2012 to Jan 2013.
### PART 3-b: INVESTIGATE THE CORRELATION ###
WITH cleaned_users AS (
SELECT	DISTINCT *
FROM	users
),
ranked_users AS (
SELECT	*,
		ROW_NUMBER() OVER (
		PARTITION BY user_guid
		ORDER BY CASE WHEN utc_correction != '#N/A' THEN 0 ELSE 1 END DESC
		) AS rn
FROM	cleaned_users
)
SELECT	*
FROM	ranked_users
WHERE	created_at >= '2013-06-01' AND created_at <= '2013-11-01';

WITH cleaned_users AS (
SELECT	DISTINCT *
FROM	users
),
ranked_users AS (
SELECT	*,
		ROW_NUMBER() OVER (
		PARTITION BY user_guid
		ORDER BY CASE WHEN utc_correction != '#N/A' THEN 0 ELSE 1 END DESC
		) AS rn
FROM	cleaned_users
)
SELECT		free_start_user, membership_type, COUNT(*)
FROM		ranked_users
WHERE		created_at >= '2013-06-01' AND created_at <= '2013-12-01'
GROUP BY	free_start_user, membership_type
ORDER BY	COUNT(*) DESC;

# free_start_user = 1, membership_type = 4 (free) is the most common during that period.
# It's because Dognition promoted free start. and during this term, total number of signups are higher than usual.

WITH cleaned_users AS (
SELECT	DISTINCT *
FROM	users
),
ranked_users AS (
SELECT	*,
		ROW_NUMBER() OVER (
		PARTITION BY user_guid
		ORDER BY CASE WHEN utc_correction != '#N/A' THEN 0 ELSE 1 END DESC
		) AS rn
FROM	cleaned_users
)
SELECT		free_start_user, membership_type, COUNT(*)
FROM		ranked_users
WHERE		created_at >= '2015-06-01' AND created_at <= '2015-11-01'
GROUP BY	free_start_user, membership_type
ORDER BY	COUNT(*) DESC;

# Same as between Jun 2013 and Nov 2013, from Jun 2015 to Oct 2015,
# the most common type of signups are free start with membership_type 4, which is free.

WITH cleaned_complete_tests AS (
SELECT	DISTINCT *
FROM	complete_tests
)
SELECT		test_name, subcategory_name, COUNT(*)
FROM		cleaned_complete_tests
WHERE		created_at >= '2015-06-01' AND created_at <= '2015-11-01'
GROUP BY	test_name, subcategory_name
ORDER BY	COUNT(*) DESC;

WITH cleaned_complete_tests AS (
SELECT	DISTINCT *
FROM	complete_tests
)
SELECT		test_name, subcategory_name, COUNT(*)
FROM		cleaned_complete_tests
GROUP BY	test_name, subcategory_name
ORDER BY	COUNT(*) DESC;

### PART 3-c: INVESTIGATE THE IDEAS ###

# 1. The Dognition assessment is too complicated
# (so that many users get to a certain point, become frustrated, and quit)

WITH cleaned_reviews AS (
SELECT	DISTINCT *
FROM	reviews
)
SELECT		subcategory_name, test_name, AVG(rating), COUNT(*)
FROM		cleaned_reviews
GROUP BY	subcategory_name, test_name
ORDER BY	AVG(rating) ASC;




# 2. There may be issues with the Dognition website, where certain webpages are prone to issues, resulting in user confusion.
WITH cleaned_site_activities AS (
SELECT	DISTINCT *
FROM	site_activities
)
SELECT		activity_type
FROM		cleaned_site_activities
GROUP BY	activity_type;

WITH cleaned_site_activities AS (
SELECT	DISTINCT *
FROM	site_activities
)
SELECT		*
FROM		cleaned_site_activities
WHERE		activity_type LIKE '%error%';


WITH cleaned_dogs AS (
SELECT 	DISTINCT *
FROM	dogs
),
cleaned_reviews AS (
SELECT	DISTINCT *
FROM	reviews
)
SELECT		breed_type, AVG(rating)
FROM (
SELECT		A.rating, B.breed_type
FROM		cleaned_reviews AS A
LEFT JOIN	cleaned_dogs AS B
ON			A.dog_guid = B.dog_guid
WHERE		A.rating IS NOT NULL AND
			B.breed_type IS NOT NULL
ORDER BY	rating DESC
) AS C
GROUP BY	breed_type
ORDER BY	AVG(rating) DESC;

