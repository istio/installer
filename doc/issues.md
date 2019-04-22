# Current issue organization

## Pipelines 

This repo is using default zenhub pipelines (if ZenHub is installed): 

| Type | Handling | 
| --- | --- | 
| New Issues | need to be triaged in x days | 
| In Progress | someone assigned to the issue and actively working on it. |  
| Backlog    | nobody assigned yet, stack ranked. Should also be set to 1.2 milestone. |
| Icebox     | not actively worked on or planned in the near term. If developers are interested - they can move to 
  Backlog or InProgress, but they need to assign themselves or some volunteer. |
| Review/QA  | we can use it if the fix is in the daily, but not yet in a release. |

## Assignee

Should be set if someone is or should be working on an issue. For example 
if it's related to some other work or PR done by a developer, or if there
are reasons to believe the assignee can be volunteered for the issue. 

Issued with an Assignee should be in Backlog, InProgress or QA pipelines.

## P0

P0 is an issue believed to be a release blocker, must be fixed. Should have 
an assignee.

