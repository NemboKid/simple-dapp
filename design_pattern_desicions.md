### Design Pattern and Security Considerations

**Upgradability**
I actively chose not to include any of the two upgradability patterns (Data Separation and Delegatecall-based proxies). 
To understand my reasoning, please read my explaining points below:

- My aim is to strive for simple contracts that are both secure and immutable. 
- It would increase the complexity of the contract and its readability, which is opposed to my purpose.
- A considerable potential of flaws and can introduce bugs, as has been seen many times. It's a topic still under heavy research and is still considered very experimental.
- The created contract is constructed for small short term projects.


**Number of Steps and Time Limit**
I chose to only let the contract maximal run for 10 weeks (8 weeks normal, then an extention can be made with 2 additional weeks). 
At first I had it for one year, but I want my contract to be simple and not to include too much money and hence be big working operations. 
As the contract is hard coded and only consists of a number of weeks (1-8, with an extention of 2 weeks),
the purpose is not attach large and complex agile projects. Four steps is perfect for smaller projects.

If the contract would run for 52 weeks, 4 steps wouldn't be sufficient. If someone wants to improve this contract and increase its scope, it needs to be part of a larger system which includes a scrum like structure
together with careful Github interaction and controlling structures for pull requests etc. 


**Roles**
The contract is designed from a company's point of view and I made this role extremelly powerful with purpose. The four steps are there to protect both the owner and the developers,
where the never needs to accept if he doesn't like the result. At the same time, if the first step isn't accepted, the developers will not continue to work since the owner is i) disatisfied or ii) not serious.
In accordance to what I wrote under "Number of Steps and Time Limit", smaller steps could increase the feeling of security for both developers and the owner. However, I wanted to 
build a very easy project that's intiutive and with hard coded steps. One improvement could be that the owner can choose number of steps and also the time for them, but I chose to 
make a short term contract for simplicity reasons. With an increased number of steps, the owner, who's perhaps not very technical, would need to 
interact with the contract more often, increasing both cost in terms of gas usage as well as complexity.

