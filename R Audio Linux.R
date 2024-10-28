################################################################################
# Audio transcription code                                                     #
# By Taylor D.H. Rockhill                                                      #
# Creative Commons Licence, 2024                                               #
# Linux edition                                                                #
################################################################################

# Install relevant packages (only need to run once):

install.packages("beepr")
install.packages("av")
install.packages("remotes")
install.packages("ggplot2")
install.packages("wordcloud2")
install.packages("dplyr")

library(av)
library(beepr)
library(ggplot2)
library(wordcloud2)
library(dplyr)

options(timeout = 1920)

Sys.setenv(WHISPER_CFLAGS = "-mavx -mavx2 -mfma -mf16c")
remotes::install_github("bnosac/audio.whisper", ref = "0.3.3", force = TRUE)
Sys.unsetenv("WHISPER_CFLAGS")

library(audio.whisper)

setwd(rstudioapi::selectDirectory())

whisper_download_model("large-v3")

model <- whisper("large-v3")

raw_file <- rstudioapi::selectFile()

av_audio_convert(raw_file, output = "output.wav", 
                 format = "wav", sample_rate = 16000)

trans <- predict(model, newdata = "output.wav", language = "en", n_threads = 4)

write.csv(trans$data, "transcript.csv")

system("transcript.csv", wait = FALSE)

wordtable <- data.frame(trans$tokens)
wordtable <- as.data.frame(table(wordtable$token))
names(wordtable) = c("word", "freq")

wordtable <- filter(wordtable, word != & freq > 1)

write.csv(wordtable, "wordtable.csv")
system("wordtable.csv", wait = FALSE)

wordcloud2(wordtable, size = 1.6, color = "random-dark")

ggplot(wordtable, aes(reorder(x = word, freq), y = freq)) + 
  geom_point() + 
  geom_segment(aes(x = word, xend = word, y = 0, yend = freq)) + 
  coord_flip() +
  xlab("Word") + ylab("Frequency")