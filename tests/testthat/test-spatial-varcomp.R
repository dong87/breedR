old.op <- options(warn = -1,  # suppressWarnings
                  show.error.messages = FALSE)  # silent try
on.exit(options(old.op))

### Scaling of spatial variance components ###
context("Scaling of the spatial variance component")

res.blk <- try(
  suppressMessages(
    remlf90(fixed  = phe_X ~ 1,
            spatial = list(model = 'blocks', 
                           coord = globulus[, c('x','y')],
                           id = 'bl'),
            data = globulus)
  )
)
    
res.spl  <- try(
  suppressMessages(
    remlf90(fixed  = phe_X ~ 1,
            spatial = list(model = 'splines', 
                           coord = globulus[, c('x','y')], 
                           n.knots = c(2, 2)), 
            data = globulus,
            method = 'em')
  )
)

res.ar  <- try(
  suppressMessages(
    remlf90(fixed  = phe_X ~ gg,
            genetic = list(model = 'add_animal', 
                           pedigree = globulus[,1:3],
                           id = 'self'), 
            spatial = list(model = 'AR', 
                           coord = globulus[, c('x','y')],
                           rho = c(.85, .8)), 
            data = globulus)
  )
)


test_that("The spatial variance component is the characteristic marginal variance of the spatial effect's contribution to the phenotypic variance", {
  expect_equal(breedR:::gmean(Matrix::diag(vcov(res.blk))), res.blk$var['spatial', 1])
  expect_equal(breedR:::gmean(Matrix::diag(vcov(res.spl))), res.spl$var['spatial', 1])
  expect_equal(breedR:::gmean(Matrix::diag(vcov(res.ar))),  res.ar$var['spatial', 1])
})

