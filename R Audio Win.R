################################################################################
# Audio transcription code                                                     #
# By Taylor D.H. Rockhill                                                      #
# Creative Commons Licence, 2023                                               #
# Windows edition                                                              #
################################################################################

# Install relevant packages (only need to run once):

install.packages("devtools")
install.packages("installr")
install.packages("remotes")
install.packages("av")
install.packages("doParallel")
install.packages("beepr")
install.packages("ggplot2")
install.packages("wordcloud2")
install.packages("dplyr")

# Load required packages (do every time):

library(installr)
library(av)
library(doParallel)
library(beepr)
library(ggplot2)
library(wordcloud2)
library(dplyr)

# Activate parallel computing (haha parallel computing go brrr):

cl <- makeCluster(detectCores(), type = "PSOCK")
registerDoParallel(cl)

# Adjust R's default timeout to accomodate the large data files:

options(timeout = 1920)

# Run once to make sure you have a C++ compiler:

install.Rtools()

# Install the audio library:

Sys.setenv(WHISPER_CFLAGS = "-mavx -mavx2 -mfma -mf16c")
remotes::install_github("bnosac/audio.whisper", ref = "0.3.3", force = TRUE)
Sys.unsetenv("WHISPER_CFLAGS")

# Open the audio library:

library(audio.whisper)

# Set working directory:

setwd(choose.dir(caption = "Choose working directory")) # Establish where you have the audio file and where you want the 
                                                        # transcript saved.

# Download the relevant language model:

whisper_download_model("large-v3")

# Set language model:

model <- whisper("large-v3")

# Convert audio file to necessary 16-bit WAV file:

raw_file <- file.choose()

av_audio_convert(raw_file, output = "output.wav", format = "wav", sample_rate = 16000)

# Create transcript:

trans <- predict(model, newdata = "output.wav", language = "en", n_threads = 4)
beep() # Notification sound to tell you when it's finished.

# Export to CSV file:

write.csv(trans$data, "transcript.csv")

# Open CSV in system's default CSV reader:

shell("transcript.csv", wait = FALSE) # Windows

# Analyse the data: 

wordtable <- data.frame(trans$tokens)
wordtable <- as.data.frame(table(wordtable$token))
names(wordtable) = c("word", "freq")

wordtable <- filter(wordtable, word != & freq > 1) # Filter out words, mistaken fragments, and words that don't appear often enough

# Export:

write.csv(wordtable, "wordtable.csv")
shell("wordtable.csv", wait = FALSE)

## Plot: 

# Wordcloud: 

wordcloud2(wordtable, size = 1.6, color = "random-dark")

# Lolly plot: 

ggplot(wordtable, aes(reorder(x = word, freq), y = freq)) + 
  geom_point() + 
  geom_segment(aes(x = word, xend = word, y = 0, yend = freq)) + 
  coord_flip() +
  xlab("Word") + ylab("Frequency")