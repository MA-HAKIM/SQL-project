--create database bookcatalogdb
--go
use bookcatalogdb
go
ALTER DATABASE bookcatalogdb
SET COMPATIBILITY_LEVEL =  140
GO
create table tags 
(
  tagid int not null identity primary key,
  tag nvarchar (30) not null
)
go 
create table publishers
( 
  publisherid int identity primary key,
  publishername nvarchar (40) not null,
  publisheremail nvarchar (50) null
 )
 go
 create table authors
 (
	authorid int identity primary key,
	authorname nvarchar(50) not null,
	email nvarchar(50) null
)
go
 create table books
( 
  bookid int identity primary key,
  title nvarchar (40) not null,
  coverprice money not null,
  publishdate date not null,
  available bit default 0,
  publisherid int not null references publishers(publisherid)
 )
go
create table booktags
(
  bookid int not null references books (bookid),
  tagid int not null references tags (tagid),
  primary key (bookid,tagid)
)
go
create table bookauthors 
(
  bookid int not null references books (bookid),
  authorid int not null references authors (authorid)
)
go

CREATE PROC spInsertBook @title NVARCHAR(40), @price MONEY, @available BIT, @publishdate DATE, @publisherid INT, @tags NVARCHAR(max), @authors NVARCHAR(max)
AS
	MERGE tags t using (select RTRIM(value) as v FROM string_split(@tags, ',')) as s
		ON t.tag = s.v
	WHEN NOT MATCHED BY TARGET
		THEN INSERT (tag) VALUES(s.v);

	INSERT INTO books (title, coverprice, publishdate,available,publisherid )
	VALUES ( @title, @price,@publishdate, IIF(@publishdate > cast(@publishdate as date), 0, @available), @publisherid)

	DECLARE @id INT
	SET @id = SCOPE_IDENTITY()
	--bookauthors
	insert into bookauthors (bookid, authorid)
	select @id, RTRIM(value)
	FROM string_split(@authors, ',') 
	--booktags
	insert into booktags (bookid, tagid)
	SELECT @id, t.tagid
	FROM
	(SELECT RTRIM(value) as value
	FROM string_split(@tags, ',')) as s
	INNER JOIN tags t ON t.tag = s.value

	RETURN;
GO
CREATE FUNCTION fnTagList(@bookid int ) RETURNS NVARCHAR(2000)
AS
BEGIN
	DECLARE @x NVARCHAR(2000)
	SET @x= (SELECT  RTRIM(LTRIM(t.tag)) + ', ' AS 'data()' 
	FROM booktags bt
	INNER JOIN tags t ON bt.tagid = t.tagid
	WHERE bookid = @bookid
	FOR XML PATH(''))
	
	SET @x= RTRIM(@x)
	SET @x =LEFT(@x, LEN(@x)-1)
	
	RETURN @x
END
GO
GO
CREATE FUNCTION fnAuthorList(@bookid int ) RETURNS NVARCHAR(2000)
AS
BEGIN
	DECLARE @x NVARCHAR(2000)
	SET @x= (SELECT  RTRIM(LTRIM(a.authorname)) + ', ' AS 'data()' 
	FROM bookauthors ba
	INNER JOIN authors a ON ba.authorid = a.authorid
	WHERE ba.bookid = @bookid
	FOR XML PATH(''))
	
	SET @x= RTRIM(@x)
	SET @x =LEFT(@x, LEN(@x)-1)
	
	RETURN @x
END
GO
CREATE VIEW vwBookInfo
AS
SELECT b.title, b.publishdate, b.coverprice, IIF(b.available = 1, 'Yes', 'No') as available, p.publishername, 
		dbo.fnTagList(b.bookid) as tags,
		dbo.fnAuthorList(b.bookid) as authors
FROM books b
INNER JOIN publishers p on b.publisherid = p.publisherid
GO
--Triggers
CREATE TRIGGER trPreventTagDelete
ON tags 
AFTER DELETE
AS
BEGIN
	 DECLARE @id INT
	 SELECT @id = tagid FROM deleted
	 IF EXISTS (SELECT 1 FROM booktags where tagid = @id)
	 BEGIN
		ROLLBACK TRANSACTION
		RAISERROR ('Tag has dependendent book. Delete them first', 16, 1)
		RETURN
	 END
END
GO
CREATE TRIGGER trPreventAuthorDelete
ON authors 
AFTER DELETE
AS
BEGIN
	 DECLARE @id INT
	 SELECT @id = authorid FROM deleted
	 IF EXISTS (SELECT 1 FROM bookauthors where authorid = @id)
	 BEGIN
		ROLLBACK TRANSACTION
		RAISERROR ('Author has dependendent book. Delete them first', 16, 1)
		RETURN
	 END
END
GO
--Paging
CREATE function fnBookPageCount(@perpage INT ) RETURNS INT
AS
BEGIN
	DECLARE @count INT
	SELECT @count= ceiling (1.0*COUNT(*)/@perpage) FROM books
	RETURN @count
END
GO
CREATE function pagedBook(@page INT, @perpage int) RETURNS TABLE
AS
RETURN (
SELECT *
FROM books
ORDER BY bookid
OFFSET (@page-1)*@perpage ROWS 
FETCH NEXT @perpage ROWS ONLY
)
GO