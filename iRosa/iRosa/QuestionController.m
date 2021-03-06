/*
 * Copyright © 2011 Michael Willekes
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 */

#import "QuestionController.h"
#import "ocRosa.h"

@implementation QuestionController

@synthesize record, control, controlIndex, formTitle, formDetails;

- (void)dealloc {
    self.record = nil;
    self.control = nil;
    self.formTitle = nil;
    self.formDetails = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // When popping back-up the navigation stack, we'll
    // update the results if we can, but if any of the
    // constraints aren't satisfied - we'll ignore it
    if (self.control)
        [record updateRecordWithControlResult:self.control];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -

- (BOOL)nextQuestion {
    
    if (![record updateRecordWithControlResult:self.control]) {
        // Answer is invalid
        UIAlertView *alert = [[UIAlertView alloc]
                                initWithTitle: @"Invalid Answer"
                                message: record.constraintMessage
                                delegate: nil
                                cancelButtonTitle:@"OK"
                                otherButtonTitles:nil];
        [alert show];
        [alert release];
        return NO;
    }
    
    Control *nextControl = nil;
    
    while ([record hasNext:self.controlIndex]) {
        self.controlIndex++;
        nextControl = [record getControl:self.controlIndex];
        if (nextControl) {
            self.control = nextControl;
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)previousQuestion {
    
    // When navigating to the previous question, we'll
    // update the results if we can, but if any of the
    // constraints aren't satisfied - we'll ignore it
    [record updateRecordWithControlResult:self.control];
    
    Control *previousControl = nil;
    
    while ([record hasPrevious:self.controlIndex]) {
        self.controlIndex--;
        previousControl = [record getControl:self.controlIndex];
        if (previousControl) {
            self.control = previousControl;
            return YES;
        }
    }
    
    return NO;
}

- (void)done {
    
    if (![record updateRecordWithControlResult:self.control]) {
        // Answer is invalid
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle: @"Invalid Answer"
                              message: record.constraintMessage
                              delegate: nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    
    self.control = nil;
    [self.record complete];
    
    [((UITableViewController*)self.formDetails).navigationController popToViewController:(UITableViewController*)self.formDetails
                                                                                animated:YES];
}

#pragma mark SelectOneView

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.control.items count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self.control.values objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
 
    NSMutableArray *selectedItems = [NSMutableArray arrayWithCapacity:[self.control.values count]];
    for (int i = 0; i < [self.control.values count]; i++) {
        [selectedItems addObject:[NSNumber numberWithBool:NO]];
    }
 
    [selectedItems replaceObjectAtIndex:row withObject:[NSNumber numberWithBool:YES]];
    
    [self.control encodeResultFromSelection:selectedItems];
}

#pragma mark SelectView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.control.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    BOOL isSelected = [[[self.control decodeResultToSelection] objectAtIndex:indexPath.row] boolValue];
    if (isSelected) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.text = [self.control.items objectAtIndex:indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSMutableArray *selectedItems = [NSMutableArray arrayWithArray:[self.control decodeResultToSelection]];

    if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        // It's already selected; Unselect it
        [selectedItems replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithBool:NO]];
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        // It's not selected; Selected it
        [selectedItems replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithBool:YES]];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }

    [self.control encodeResultFromSelection:selectedItems];
}

#pragma mark Input

- (void)updateResultUsingContentsOfTextField:(id)sender {
    self.control.result = ((UITextField *)sender).text;
}

#pragma mark TextView

- (void)textViewDidEndEditing:(UITextView *)textView {
    self.control.result = textView.text;
    [textView resignFirstResponder];
}

@end
