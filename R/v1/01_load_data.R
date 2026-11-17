# Load raw NHANES SAS transport files.

library(haven)

data_dir <- "Data"

read_nhanes <- function(file_name) {
  read_xpt(file.path(data_dir, file_name))
}

demo <- read_nhanes("DEMO_L.xpt")
bmx <- read_nhanes("BMX_L.xpt")
bpxo <- read_nhanes("BPXO_L.xpt")
diq <- read_nhanes("DIQ_L.xpt")
ghb <- read_nhanes("GHB_L.xpt")
glu <- read_nhanes("GLU_L.xpt")
tchol <- read_nhanes("TCHOL_L.xpt")
hdl <- read_nhanes("HDL_L.xpt")
smq <- read_nhanes("SMQ_L.xpt")
paq <- read_nhanes("PAQ_L.xpt")
slq <- read_nhanes("SLQ_L.xpt")
alq <- read_nhanes("ALQ_L.xpt")

message("Loaded NHANES source files from ", normalizePath(data_dir))
