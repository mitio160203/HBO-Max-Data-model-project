CREATE DATABASE MovieStreamingPlatform;

USE MovieStreamingPlatform;

CREATE TABLE SubscriptionPlan (
    Plan_Id INT PRIMARY KEY IDENTITY,
    Plan_Type NVARCHAR(50) NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    Quality NVARCHAR(50) NOT NULL,
    Duration INT NOT NULL
);

CREATE TABLE UserAccount (
    User_Id INT PRIMARY KEY IDENTITY,
    Name NVARCHAR(50) NOT NULL,
    Email NVARCHAR(50) UNIQUE NOT NULL,
    Password NVARCHAR(50) NOT NULL,
    Date_of_Birth DATE NOT NULL,
    Date_Joined DATE NOT NULL
);

CREATE TABLE Subscription (
    Subscription_ID INT PRIMARY KEY IDENTITY,
    User_ID INT FOREIGN KEY REFERENCES UserAccount(User_Id),
    Start_Date DATE NOT NULL,
    End_Date DATE,
    Plan_ID INT FOREIGN KEY REFERENCES SubscriptionPlan(Plan_Id)
);

CREATE TABLE Payment (
    Payment_Id INT PRIMARY KEY IDENTITY,
    User_ID INT FOREIGN KEY REFERENCES UserAccount(User_Id),
    Subscription_ID INT FOREIGN KEY REFERENCES Subscription(Subscription_ID),
    Payment_Method NVARCHAR(50) NOT NULL,
    Payment_Date DATE NOT NULL,
    Amount DECIMAL(10, 2) NOT NULL,
    Status NVARCHAR(50) NOT NULL
);
ALTER TABLE Payment
ADD CONSTRAINT chk_Payment_Status CHECK (Status IN ('completed', 'pending'));

CREATE TABLE Profile (
    Profile_Id INT PRIMARY KEY IDENTITY,
    User_ID INT FOREIGN KEY REFERENCES UserAccount(User_Id),
    Profile_Name NVARCHAR(50) NOT NULL,
    Age_Group NVARCHAR(50) NOT NULL CHECK (Age_Group IN ('kids', 'adults'))
);

CREATE TABLE Content (
    Content_Id INT PRIMARY KEY IDENTITY,
    Title NVARCHAR(200) NOT NULL,
    Genre NVARCHAR(50),
    Release_date DATE,
    Type NVARCHAR(50) NOT NULL CHECK (Type IN ('movie', 'tv_series')),
    Duration TIME NULL,                          
    Episode_Count INT NULL,                      
    Age_Rating NVARCHAR(10),
    CHECK (
        (Type = 'movie' AND Duration IS NOT NULL AND Episode_Count IS NULL) OR
        (Type = 'tv_series' AND Episode_Count IS NOT NULL AND Duration IS NULL)
    )
);

CREATE TABLE Recommendation (
    Recommendation_ID INT PRIMARY KEY IDENTITY,
    Profile_ID INT FOREIGN KEY REFERENCES Profile(Profile_Id),
    Content_ID INT FOREIGN KEY REFERENCES Content(Content_Id),
    Recommendation_Type NVARCHAR(50),
    Recommendation_Date DATE NOT NULL
);

CREATE TABLE WatchHistory (
    History_Id INT PRIMARY KEY IDENTITY,
    Profile_ID INT FOREIGN KEY REFERENCES Profile(Profile_Id),
    Content_ID INT FOREIGN KEY REFERENCES Content(Content_Id),
    Start_Time DATETIME,
    End_Time DATETIME,
    Completion_Status NVARCHAR(50)
);

USE [MovieStreamingPlatform]
GO
/****** Object:  Trigger [dbo].[UpdateSubscriptionStatus]    Script Date: 4.12.2024 г. 23:20:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TRIGGER [dbo].[UpdateSubscriptionStatus]
ON [dbo].[Subscription]
AFTER UPDATE
AS
BEGIN
    UPDATE Subscription
    SET Status = 'expired'
    WHERE End_Date < GETDATE() AND Status <> 'expired';
END;

USE [MovieStreamingPlatform]
GO
/****** Object:  StoredProcedure [dbo].[AddContent]    Script Date: 4.12.2024 г. 23:22:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[AddContent]
    @Title NVARCHAR(200),
    @Genre NVARCHAR(50),
    @ReleaseDate DATE,
    @Type NVARCHAR(50),
    @Duration TIME = NULL,
    @EpisodeCount INT = NULL,
    @AgeRating NVARCHAR(10) = NULL
AS
BEGIN
    IF @Type NOT IN ('movie', 'tv_series')
    BEGIN
        RAISERROR ('Invalid Type. Must be "movie" or "tv_series".', 16, 1);
        RETURN;
    END

    IF @Type = 'movie' AND @Duration IS NULL
    BEGIN
        RAISERROR ('Movies must have a Duration.', 16, 1);
        RETURN;
    END

    IF @Type = 'tv_series' AND @EpisodeCount IS NULL
    BEGIN
        RAISERROR ('TV Series must have an Episode Count.', 16, 1);
        RETURN;
    END

    INSERT INTO Content (Title, Genre, Release_date, Type, Duration, Episode_Count, Age_Rating)
    VALUES (@Title, @Genre, @ReleaseDate, @Type, @Duration, @EpisodeCount, @AgeRating);
END;



USE [MovieStreamingPlatform]
GO
/****** Object:  UserDefinedFunction [dbo].[GetTotalWatchTime]    Script Date: 4.12.2024 г. 23:23:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[GetTotalWatchTime] (@ProfileId INT)
RETURNS INT
AS
BEGIN
    RETURN (
        SELECT SUM(DATEDIFF(MINUTE, Start_Time, End_Time))
        FROM WatchHistory
        WHERE Profile_ID = @ProfileId
          AND Completion_Status = 'completed'
    );
END;