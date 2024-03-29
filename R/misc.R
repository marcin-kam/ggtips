# This file is part of ggtips (R package to display tooltips on svg ggplot)
#
# @author Pawel Piatkowski
#
# Copyright 2018 Genentech, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining
# copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#' Auxiliary function removing `textLength` and `lengthAdjust` from SVG data
#'
readSvgAndRemoveTextLength <- function(filename){
  gsub(
    pattern = paste0(" (textLength|lengthAdjust)='(.*?)'"),
    replacement = '',
    x = readChar(filename, file.info(filename)$size, useBytes = TRUE)
  )
}

#' Freeze factor levels
#'
#' Reorders factor levels in a data frame, and - optionally -
#' converts character columns to factors.
#'
#' @param df A data frame.
#' @param characterToFactor If TRUE, converts strings to factors.
#'
#' @return A data frame.
freezeFactorLevels <- function(df, characterToFactor = FALSE){
  tibble::as_tibble(lapply(
    X = df,
    FUN = function(x){
      if (is.factor(x) || (characterToFactor && is.character(x))){
        factor(x = x, levels = unique(x))
      } else {
        x
      }
    }
  ))
}

#' load Front-End dependencies (use this function in any rendered content and
#' it will load the files only once)
getDependencies <- function() {
  htmltools::htmlDependency(
    name = "ggtips",
    package = "ggtips",
    version = packageVersion("ggtips"),
    src = "ggtips",
    script = c("ggtips.js", "jquery.resize.js"),
    stylesheet = "ggtips.css"
  )
}

#' check if loaded ggplot2 major version is 2
isGgplot2 <- function() {
  packageVersion("ggplot2")$major == 2L
}


#' Gets fill colors of bars if plot is a barplot
#'
#' @param p ggplot object
#'
#' @return vector of fill colors or NULL if no \code{rect} geom in the plot
getBarColors <- function(p) {
  if (!"ggplot" %in% class(p)) {
    warning("p argument should ba a valid ggplot object")
    return(NULL)
  }

  gt <- gridExtra::grid.arrange(p)[[1]][[1]]
  panel_idx <- grep(pattern = "panel", x = gt$grobs)

  fills <- lapply(panel_idx, function(p) {
    grob_children <- gt$grobs[[p]]$children
    rect_idx <- grep(pattern = "geom_rect\\.rect", x = names(grob_children))
    if (length(rect_idx) == 0)
      return()
    fill <- grob_children[[rect_idx]]$gp$fill
    # remove FF opacity from the end of the hex code as it may cause problems when matching with svg
    # on the front-end
    gsub(pattern = "(^#[0-9A-Z]{6})FF$", x = toupper(fill), replacement = "\\1")
  })
  fills <- unlist(fills)
  if (length(fills) == 1) {
    # if there are more than one element it will be parsed as an array in JavaScript even if it's
    # a vector in R; in case 'fills' is a one-element list it should be  treated as a list
    fills <- as.list(fills)
  }
  return(fills)
}
