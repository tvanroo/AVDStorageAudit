# Fix for "Query Pending" Issue in Workbook

## Problem
The workbook shows "query pending" in the Log Analytics workspace dropdown because there's a conflict between:
1. The workbook's `sourceId` (automatically set to the deployed workspace)  
2. The workspace parameter trying to query for all available workspaces

## Root Cause
When a workbook is deployed with a `sourceId`, it should automatically use that workspace, but the embedded workspace parameter is trying to override this with a cross-component query.

## Solutions

### Option 1: Remove workspace parameter (Recommended)
Since the workbook is deployed with a specific `sourceId`, we can remove the workspace parameter entirely.

### Option 2: Set workspace parameter to current workspace
Modify the workspace parameter to default to the current workspace instead of querying all workspaces.

### Option 3: Fix the workspace parameter query
The current query uses `crossComponentResources: ["value::all"]` which may not work correctly in all contexts.

## Analysis Needed
Let me check the current embedded workbook configuration and implement the best fix.
