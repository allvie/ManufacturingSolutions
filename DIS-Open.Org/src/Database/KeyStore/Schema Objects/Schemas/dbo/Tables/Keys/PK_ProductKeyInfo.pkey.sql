﻿ALTER TABLE [dbo].[ProductKeyInfo]
    ADD CONSTRAINT [PK_ProductKeyInfo] PRIMARY KEY CLUSTERED ([ProductKeyID] ASC) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);
