#ANA 505 - Assignment 2 - Tze Ning Wong (Nico)
# Predictive Model for Los Angeles Dodgers Promotion and Attendance (R)

#these libraries are called in order visualize the data and also call regression functions for our machine learning purposes. R does offer basic visualization but
#other packages could offer better visualizations and have better functionality. That's the beauty of the open source because there can be multiple packages to do the same thing
#but some have additonal features for specific use cases/preferable by different people
library(car)  # special functions for linear regression
library(lattice)  # graphics package

# read in data and create a data frame called dodgers
dodgers <- read.csv("dodgers.csv")
print(str(dodgers))  # check the structure of the data frame

# define an ordered day-of-week variable 
# for plots and data summaries
dodgers$ordered_day_of_week <- with(data=dodgers,
  ifelse ((day_of_week == "Monday"),1, #based on the dataframe, if the value in the column is Monday, it will have the value of 1, Tuesday =2, and so on. 
  ifelse ((day_of_week == "Tuesday"),2, #this provides an order for the day of the week, since the values are just strings, R is unable to recognize which day comes first
  ifelse ((day_of_week == "Wednesday"),3,
  ifelse ((day_of_week == "Thursday"),4,
  ifelse ((day_of_week == "Friday"),5,
  ifelse ((day_of_week == "Saturday"),6,7)))))))
#the function factor is used to encode the vector as a categorical variable with different labels (week of the day) and in what order (if applicable)
dodgers$ordered_day_of_week <- factor(dodgers$ordered_day_of_week, levels=1:7,
labels=c("Mon", "Tue", "Wed", "Thur", "Fri", "Sat", "Sun"))

# exploratory data analysis with standard graphics: attendance by day of week
#this is for viewing the attendance by day of the week visualize what days have high or low attendance and whether the day of the week influences attendance
with(data=dodgers,plot(ordered_day_of_week, attend/1000, 
xlab = "Day of Week", ylab = "Attendance (thousands)", 
col = "violet", las = 1))

# when do the Dodgers use bobblehead promotions
#this is to view on what days were bobblehead promotions held, and if that has an impact on attendance compared to days that did not
with(dodgers, table(bobblehead,ordered_day_of_week)) # bobbleheads on Tuesday

# define an ordered month variable 
# for plots and data summaries
dodgers$ordered_month <- with(data=dodgers,
  ifelse ((month == "APR"),4, #based on the dataframe, if the value in the column is April, it will have the value of 4, May =5, and so on. 
  ifelse ((month == "MAY"),5, #this provides an order for the month because since it is not of date format, R is not able to detect the order of these months
  ifelse ((month == "JUN"),6,
  ifelse ((month == "JUL"),7,
  ifelse ((month == "AUG"),8,
  ifelse ((month == "SEP"),9,10)))))))
#the function factor is used to encode the vector as a categorical variable with different labels (month) and in what order (if applicable)
dodgers$ordered_month <- factor(dodgers$ordered_month, levels=4:10,
labels = c("April", "May", "June", "July", "Aug", "Sept", "Oct"))

# exploratory data analysis with standard R graphics: attendance by month 
#this is for viewing the attendance by monthk visualize what months have high or low attendance and whether the month influences attendance
with(data=dodgers,plot(ordered_month,attend/1000, xlab = "Month", 
ylab = "Attendance (thousands)", col = "light blue", las = 1))

# exploratory data analysis displaying many variables
# looking at attendance and conditioning on day/night
# the skies and whether or not fireworks are displayed
library(lattice) # used for plotting 
# let us prepare a graphical summary of the dodgers data
# the lattice library allows to plot 4 sub charts on the same chart with different conditions for day/night, skies and whether fireworks were displayed
# this allows us to beter compare it all at once rather plotting it one by one and see if any of these features complement each other or makes no difference
group.labels <- c("No Fireworks","Fireworks")
group.symbols <- c(21,24)
group.colors <- c("black","black") 
group.fill <- c("black","red")
xyplot(attend/1000 ~ temp | skies + day_night, 
    data = dodgers, groups = fireworks, pch = group.symbols, 
    aspect = 1, cex = 1.5, col = group.colors, fill = group.fill,
    layout = c(2, 2), type = c("p","g"),
    strip=strip.custom(strip.levels=TRUE,strip.names=FALSE, style=1),
    xlab = "Temperature (Degrees Fahrenheit)", 
    ylab = "Attendance (thousands)",
    key = list(space = "top", 
        text = list(rev(group.labels),col = rev(group.colors)),
        points = list(pch = rev(group.symbols), col = rev(group.colors),
        fill = rev(group.fill))))                  
# attendance by opponent and day/night game
#allows viewing of the attendance by opponent factoring in the time of day in the form of box and whisker plots just to see if the opposing teams influences attendance 
#while also looking at the time of day
group.labels <- c("Day","Night")
group.symbols <- c(1,20)
group.symbols.size <- c(2,2.75)
bwplot(opponent ~ attend/1000, data = dodgers, groups = day_night, 
    xlab = "Attendance (thousands)",
    panel = function(x, y, groups, subscripts, ...) 
       {panel.grid(h = (length(levels(dodgers$opponent)) - 1), v = -1)
        panel.stripplot(x, y, groups = groups, subscripts = subscripts, 
        cex = group.symbols.size, pch = group.symbols, col = "darkblue")
       },
    key = list(space = "top", 
    text = list(group.labels,col = "black"),
    points = list(pch = group.symbols, cex = group.symbols.size, 
    col = "darkblue")))
     
# employ training-and-test regimen for model validation
set.seed(1234) # set seed for repeatability of training-and-test split
#here it is creating a new column with integers of 1 and 2 to separate the train and test dataset. 2/3 of the dataset will be used for training while 1/3 will be for testing.
# the numbers will be applied at random to the each row of the existing dataset.
training_test <- c(rep(1,length=trunc((2/3)*nrow(dodgers))),
rep(2,length=(nrow(dodgers) - trunc((2/3)*nrow(dodgers)))))
dodgers$training_test <- sample(training_test) # random permutation 
dodgers$training_test <- factor(dodgers$training_test, 
  levels=c(1,2), labels=c("TRAIN","TEST"))
dodgers.train <- subset(dodgers, training_test == "TRAIN")
print(str(dodgers.train)) # check training data frame
dodgers.test <- subset(dodgers, training_test == "TEST")
print(str(dodgers.test)) # check test data frame

# specify a simple model with bobblehead entered last
#it is running a linear regression model on the training dataset with features of month, week and bobblehead promotions, and the target label being attendance
my.model <- {attend ~ ordered_month + ordered_day_of_week + bobblehead}
# fit the model to the training set
train.model.fit <- lm(my.model, data = dodgers.train)
# summary of model fit to the training set
# provides a summary of the results including residuals, coefficients, R-squared, adjusted R-squared, F-stat. These information will give a good idea of the model performance.
print(summary(train.model.fit))
# training set predictions from the model fit to the training set
dodgers.train$predict_attend <- predict(train.model.fit) 
# test set predictions from the model fit to the training set
dodgers.test$predict_attend <- predict(train.model.fit, 
  newdata = dodgers.test)

# compute the proportion of response variance
# accounted for when predicting out-of-sample
# this is the square of the the correlation of observed and predicted attendance
cat("\n","Proportion of Test Set Variance Accounted for: ",
round((with(dodgers.test,cor(attend,predict_attend)^2)),
  digits=3),"\n",sep="")
# merge the training and test sets for plotting
dodgers.plotting.frame <- rbind(dodgers.train,dodgers.test)

# generate predictive modeling visual for management
# visualize the regression model performance on how bobbleheads affected attendance. This was predicted for the training data and test data and visualized side by side.
group.labels <- c("No Bobbleheads","Bobbleheads")
group.symbols <- c(21,24)
group.colors <- c("black","black") 
group.fill <- c("black","red")  
xyplot(predict_attend/1000 ~ attend/1000 | training_test, 
       data = dodgers.plotting.frame, groups = bobblehead, cex = 2,
       pch = group.symbols, col = group.colors, fill = group.fill, 
       layout = c(2, 1), xlim = c(20,65), ylim = c(20,65), 
       aspect=1, type = c("p","g"),
       panel=function(x,y, ...)
            {panel.xyplot(x,y,...)
             panel.segments(25,25,60,60,col="black",cex=2)
            },
       strip=function(...) strip.default(..., style=1),
       xlab = "Actual Attendance (thousands)", 
       ylab = "Predicted Attendance (thousands)",
       key = list(space = "top", 
              text = list(rev(group.labels),col = rev(group.colors)),
              points = list(pch = rev(group.symbols), 
              col = rev(group.colors),
              fill = rev(group.fill))))                   
# use the full data set to obtain an estimate of the increase in
# attendance due to bobbleheads, controlling for other factors 
my.model.fit <- lm(my.model, data = dodgers)  # use all available data
print(summary(my.model.fit))
# tests statistical significance of the bobblehead promotion
# type I anova computes sums of squares for sequential tests
print(anova(my.model.fit))  
#compute the estimated coefficients for each feature and their effect on attendance 
cat("\n","Estimated Effect of Bobblehead Promotion on Attendance: ",
round(my.model.fit$coefficients[length(my.model.fit$coefficients)],
digits = 0),"\n",sep="")
# standard graphics provide diagnostic plots
# visualize how well the model fits to the historical data
plot(my.model.fit)
# additional model diagnostics drawn from the car package
library(car)
#plot the residual of the simple linear regression model of the dataset against the independent variable
residualPlots(my.model.fit)
#draw a plot of the response on the vertical axis vs a linear combination of regressors in the mean function on the horizontal axis
marginalModelPlots(my.model.fit)
#The Bonferroni Outlier Tests uses a t distribution to test whether the model's largest studentized residual value's outlier status is statistically 
#different from the other observations in the model. A significant p-value indicates an extreme outlier that warrants further examination.
print(outlierTest(my.model.fit))


