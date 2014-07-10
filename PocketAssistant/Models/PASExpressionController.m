//
//  PASExpressionController.m
//  PocketAssistant
//
//  Created by Sapa Denys on 06.07.14.
//  Copyright (c) 2014 Sapa Denys. All rights reserved.
//

#import "PASExpressionController.h"
#import "PASExpressionFormatter.h"

typedef NS_ENUM(NSInteger, PASExpressionControllerState) {
	PASExpressionControllerStatePrint,
	PASExpressionControllerStateEnterFirstOperand,
	PASExpressionControllerStateEnterOperator,
	PASExpressionControllerStateEnterSecondOperand
};

typedef NS_ENUM(NSInteger, PASBaseOperatorsCode) {
	PASBaseOperatorsCodePlus = 43,
	PASBaseOperatorsCodeMinus = 8211,
	PASBaseOperatorsCodeMultiply = 10005,
	PASBaseOperatorsCodeDelivery = 47,
};

static const NSInteger kPASEqualCode = '=';
static const NSInteger kPASClearCode = 'C';


@interface PASExpressionController ()

@property (nonatomic) PASExpressionControllerState controllerState;
@property (nonatomic, strong) PASExpressionModel *operationModel;

@end

@implementation PASExpressionController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _operationModel = [PASExpressionModel new];
		_controllerState = PASExpressionControllerStatePrint;
		[_operationModel addListener:self];
    }
    return self;
}

- (void)dealloc
{
	[_operationModel removeListener:self];
}

- (void)fillModelWithNextCharacter:(NSString *)character
{
	if ([character characterAtIndex:0] == kPASClearCode) {
		
		self.controllerState = PASExpressionControllerStatePrint;
		[self.operationModel cleanModel];
		[PASExpressionFormatter formattedStringFromExpression:self.operationModel];
		
		return;
	}
	
	switch (self.controllerState) {
		case PASExpressionControllerStatePrint:
			[PASExpressionFormatter formattedStringFromExpression:self.operationModel];
			
			if ([self isCharacterNumber:character]) {
				[self.operationModel cleanModel];
				self.controllerState = PASExpressionControllerStateEnterFirstOperand;
				[self.operationModel appendToFirstOperand:character];
			}
			break;
			
		case PASExpressionControllerStateEnterFirstOperand:
		{
			if ([self isCharacterNumber:character]) {
				[self.operationModel appendToFirstOperand:character];
			} else  if ([character characterAtIndex:0] != kPASEqualCode) {
				self.controllerState = PASExpressionControllerStateEnterOperator;
				[self.operationModel addOperator:character];
			}
			break;
		}
			
		case PASExpressionControllerStateEnterOperator:
			if ([self isCharacterNumber:character]) {
				self.controllerState = PASExpressionControllerStateEnterSecondOperand;
				[self.operationModel appendToSecondOperand:character];
			}
			break;
			
		case PASExpressionControllerStateEnterSecondOperand:
			if ([self isCharacterNumber:character]) {
				[self.operationModel appendToSecondOperand:character];
			} else {
				
				
				if ([character characterAtIndex:0] == kPASEqualCode) {
					self.controllerState = PASExpressionControllerStatePrint;
					[self calculateOperationResult];
					[PASExpressionFormatter formattedStringFromExpression:self.operationModel];
					
//					[self.operationModel cleanModel];
				}
			}
			break;
			
		default:
			break;
	}
}

- (void)calculateOperationResult
{
	int symbolCode = [self.operationModel.baseOperator characterAtIndex:0];
	
	switch (symbolCode) {
		case PASBaseOperatorsCodePlus:
			self.operationModel.result = [NSString stringWithFormat:@"%i", [self.operationModel.firstOperand integerValue] + [self.operationModel.secondOperand integerValue]];
			break;
			
		case PASBaseOperatorsCodeMinus:
						self.operationModel.result = [NSString stringWithFormat:@"%i", [self.operationModel.firstOperand integerValue] - [self.operationModel.secondOperand integerValue]];
			break;
			
		case PASBaseOperatorsCodeMultiply:
						self.operationModel.result = [NSString stringWithFormat:@"%i", [self.operationModel.firstOperand integerValue] * [self.operationModel.secondOperand integerValue]];
			break;
			
		case PASBaseOperatorsCodeDelivery:
						self.operationModel.result = [NSString stringWithFormat:@"%.2f", [self.operationModel.firstOperand integerValue] / ([self.operationModel.secondOperand integerValue] * 1.)];
			break;
			
		default:
			break;
	}
}

- (BOOL)isCharacterNumber:(NSString *)character
{
	return isnumber([character characterAtIndex:0]);
}

+ (BOOL)automaticallyNotifiesObserversOfFormattedModelPresentation
{
	return NO;
}

#pragma mark PASExpressionModelObserver

- (void)expressionModelDidChange:(PASExpressionModel *)model
{
	[self willChangeValueForKey:@"formattedModelPresentation"];
	_formattedModelPresentation = [PASExpressionFormatter formattedStringFromExpression:model];
	[self didChangeValueForKey:@"formattedModelPresentation"];
}

@end
