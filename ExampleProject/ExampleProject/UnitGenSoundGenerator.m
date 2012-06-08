//
//  UnitGenSoundGenerator.m
//  ExampleProject
//
//  Created by Adam Boulanger on 6/7/12.
//  Copyright (c) 2012 Hear For Yourself. All rights reserved.
//

#import "UnitGenSoundGenerator.h"

#import "CSDSineTable.h"
#import "CSDParam.h"
#import "CSDParamArray.h"

typedef enum
{
    kPValuePitchTag = 4
}kPValueTag;

@implementation UnitGenSoundGenerator

-(id)initWithOrchestra:(CSDOrchestra *)newOrchestra
{
    self = [super initWithOrchestra:newOrchestra];
    if (self) {
        //H4Y - ARB: create sign function with variable partial strengths
        float partialStrengths[] = {1.0f, 0.5f, 1.0f};
        CSDParamArray * partialStrengthParamArray = [CSDParamArray paramFromFloats:partialStrengths count:3];
        
        CSDSineTable * iSine = [[CSDSineTable alloc] initWithOutput:@"iSine" TableSize:4096 PartialStrengths:partialStrengthParamArray];
        [self addFunctionStatement:iSine];
        
        //TODO: writing output in csound as string "aLine" is BAD
        //NOTE:  duration of unitgenerator set from p3 with NOTE_DURATION_PVALUE
        myLine = [[CSDLine alloc] initWithOutput:@"kline"
              iStartingValue:[CSDParam paramWithFloat:0.5] 
                   iDuration:[CSDParam paramWithPValue:kPValueTagDuration]   
                iTargetValue:[CSDParam paramWithInt:1.5]];
        [self addOpcode:myLine];
        
        //Init LineSegment_a, without CSDParamArray Functions like line
        myLineSegment_a = [[CSDLineSegment alloc] initWithOutput:@"kLineSegA"
                                         iFirstSegmentStartValue:[CSDParam paramWithInt:110]
                                           iFirstSegmentDuration:[CSDParam paramWithPValue:kPValueTagDuration] 
                                       iFirstSegementTargetValue:[CSDParam paramWithInt:330]];
        
        //Init LineSegment_b, includes CSDParamArray and behaves like breakpoint generator
        //NOTE: paramAray shouldn't just be initFromFloats, but should incorporate CSDParam 
        //NOTE: need to do math on duration(p3) especially to calculate breakpoint durations
        float breakpoints[] = {3.0f, 1.5f, 3.0f, 0.5};
        CSDParamArray * breakpointParamArray = [CSDParamArray paramFromFloats:breakpoints count:4];
        myLineSegment_b = [[CSDLineSegment alloc] initWithOutput:@"kLineSegB" 
                                         iFirstSegmentStartValue:[CSDParam paramWithFloat:0.5]
                           //iFirstSegmentDuration:[CSDParam paramWithPValue:(kPValueTagDuration / 3)
                                           iFirstSegmentDuration:[CSDParam paramWithInt:3]
                                       iFirstSegementTargetValue:[CSDParam paramWithFloat:0.2] 
                                                    SegmentArray:breakpointParamArray];
        [self addOpcode:myLineSegment_a];
        [self addOpcode:myLineSegment_b];
        
        //H4Y - ARB: create fmOscillator with sine, lines for pitch, modulation, and modindex
        myFMOscillator = [[CSDFoscili alloc] 
                initFMOscillatorWithAmplitude:[CSDParam paramWithFloat:0.4] 
                                       kPitch:[CSDParam paramWithOpcode:myLineSegment_a]
                                     kCarrier:[CSDParam paramWithInt:1]
                                  xModulation:[CSDParam paramWithOpcode:myLine]
                                    kModIndex:[CSDParam paramWithOpcode:myLineSegment_b]
                                FunctionTable:iSine 
                             AndOptionalPhase:nil];
        [myFMOscillator setOutput:FINAL_OUTPUT];
        [self addOpcode:myFMOscillator];
    }
    return self;
}

-(void)playNoteForDuration:(float)dur 
{
    int instrumentNumber = [[orchestra instruments] indexOfObject:self] + 1;
    NSString * note = [NSString stringWithFormat:@"%0.2f", dur];
    [[CSDManager sharedCSDManager] playNote:note OnInstrument:instrumentNumber];

}

@end