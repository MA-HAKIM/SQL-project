use bookcatalogdb
go
--Initial data
insert into tags values ('Programming'),('.NET'), ('C#'), ('Database'), ('SQL Server'), ('SQL'),
						('Basic Computing'),('Alogorithm'), ('ASP'),('ASP.NET'), ('MVC')
GO
INSERT INTO authors VALUES ('McDonnel', null), ('Jo Finn', 'jfinn@aol.com'), ('M Antonio', null), ('S Maria', null),
					('K watson', 'watson@mc.co.nz'), ('J Sharp', 'jsharp@magamail.com'), ('J Robbs', null)
GO
INSERT INTO publishers VALUES ('Northwick publishing', null), ('Southwick publishing', null), ('Eastwick publishing', null),
								('Westwick publishing', null)
GO
--Test Book Insert
EXEC spInsertBook @title ='C# Fundamental',
		@price = 59.99,
		@available = 1, 
		@publishdate ='2017-07-01',
		@publisherid=1,
		@tags = 'Programming, C#, .NET',
		@authors = '1, 2'
GO
SELECT *FROM books
SELECT * FROM bookauthors
SELECT * FROM booktags
GO
--Helper view
--Test
SELECT dbo.fnTagList(1)
GO
--Test
SELECT dbo.fnAuthorList(1)
GO
SELECT * FROM vwBookInfo
GO
--Test Trigger
SELECT * FROM authors
DELETE FROM authors WHERE authorid=1
SELECT * FROM authors
GO
SELECT * FROM tags
DELETE FROM tags WHERE tagid=1
SELECT * FROM tags
GO
--Test paged book
SELECT * FRom pagedBook(1, 5)
GO
