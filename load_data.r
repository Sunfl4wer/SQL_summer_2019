library(RMySQL)
trans_df <- read.csv("https://query.data.world/s/x74iyfc47er6bwyb3jwotg6j6gznwc", header=TRUE, stringsAsFactors=FALSE, sep=";");
conn <- dbConnect(RMySQL::MySQL(),
                     dbname = "bankclients",
                     host = "localhost",
                     port = 3306,
                     user = "user",
                     password = "123")
dbWriteTable(conn, "transaction_table", trans_df, append = TRUE, row.names = FALSE)
