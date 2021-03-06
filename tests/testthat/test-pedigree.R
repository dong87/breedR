#### pedigree building and checking ####
old.op <- options(warn = -1,  # suppressWarnings
                  show.error.messages = FALSE)  # silent try
on.exit(options(old.op))

context("Pedigree")

# Retrieve pedigree from remlf90 objects
res.lm <- try(suppressMessages(remlf90(y~1, dat = data.frame(y=rnorm(100)))))
test_that('get_pedigree() returns NULL when there is no genetic effect', {
  expect_true(is.null(get_pedigree(res.lm)))
})

# Toy dataset with silly pedigree
test.dat <- data.frame(matrix(sample(100, 15), 5, 3,
                              dimnames = list(NULL, c('self', 'sire', 'dam'))),
                       y = rnorm(5))
ped.fix <- build_pedigree(1:3, data = test.dat)
test.res <- try(
  suppressMessages(
    remlf90(y~1,
            genetic = list(model = 'add_animal',
                           pedigree = test.dat[, 1:3],
                           id = 'self'),
            data = test.dat)
  )
)

test_that('remlf90() builds and recodes the pedigree', {
  expect_false(inherits(test.res, 'try-error'))
})

test_that('get_pedigree() returns the recoded pedigree', {
  expect_identical(ped.fix, get_pedigree(test.res))
})

# Use the pedigree in data(m4) and shuffle the codes
data(m4)
ped <- as.data.frame(m4)[, c('self', 'dad', 'mum')]
test_that('The pedigree from m4 is not complete, but otherwise correct', {
  expect_that(!check_pedigree(ped)['full_ped'], is_true());
  expect_that(all(check_pedigree(ped)[-1]), is_true())
})

# Generate a crazy map
mcode <- max(ped, na.rm = TRUE)
map <- rep(NA, mcode)
set.seed(1234)
map <- sample(10*mcode, size = mcode)

# Generate a crazy pedigree that fails all checks
ped_shuffled <- sapply(ped, function(x) map[x])
# Introduce some unknown parents either with NA or with 0
ped_shuffled[, 2:3][sample(2*nrow(ped), 200)] <- c(0, NA)

test_that('The shuffled pedigree fails all checks', {
  expect_that(all(!check_pedigree(ped_shuffled)), is_true())
})

# Reorder and recode 
ped_fix <- build_pedigree(1:3, data = ped_shuffled)
test_that('build_pedigree() fixes everything', {
  expect_that(all(check_pedigree(ped_fix)), is_true())
})


# Check that remlf90 handles correctly recoded pedigrees
# by comparing the genetics evaluations of a dataset with or without
# a shuffled pedigree

data(m1)
dat <- as.data.frame(m1)
ped <- get_pedigree(m1)

res_ok <- try(
  suppressMessages(
    remlf90(fixed = phe_X ~ sex, 
            genetic = list(model = 'add_animal', 
                           pedigree = ped,
                           id = 'self'), 
            data = dat)
  )
)

# Shuffle the pedigree
mcode <- max(as.data.frame(ped), na.rm = TRUE)
map <- rep(NA, mcode)
set.seed(1234)
map <- sample(10*mcode, size = mcode)
m1_shuffled <- m1
m1_shuffled$Data[, 1:3] <- sapply(as.data.frame(ped), function(x) map[x])

ped_fix <- build_pedigree(1:3, data = as.data.frame(get_pedigree(m1_shuffled)))

res_shuffled <- try(
  suppressMessages(
    remlf90(fixed = phe_X ~ sex,
            genetic = list(model = 'add_animal', 
                           pedigree = ped_fix,
                           id = 'self'), 
            data = as.data.frame(m1_shuffled))
  )
)

# Except the call, and the reml output everything must be the same
# Update: also need to omit the shuffled random effects estimations
# which should be the same, but reordered
test_that('remlf90 handles recoded pedigrees correctly', {
  omit.idx <- match(c('call', 'effects', 'reml', 'ranef'), names(res_ok))
  expect_that(res_ok[-omit.idx], equals(res_shuffled[-omit.idx]))
})